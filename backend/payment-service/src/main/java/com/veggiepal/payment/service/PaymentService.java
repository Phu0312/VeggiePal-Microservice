package com.veggiepal.payment.service;

import com.veggiepal.payment.dto.response.PaymentOrderResponse;
import com.veggiepal.payment.entity.*;
import com.veggiepal.payment.exception.*;
import com.veggiepal.payment.payos.*;
import com.veggiepal.payment.repository.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PaymentService {
    private static final Logger log = LoggerFactory.getLogger(PaymentService.class);
    /** Minimum gap between payOS lookups for one order while the client polls it. */
    private static final Duration SYNC_INTERVAL = Duration.ofSeconds(5);

    private final PaymentOrderRepository orders;
    private final SubscriptionPlanRepository plans;
    private final SubscriptionService subscriptionService;
    private final PayOsGateway payOs;
    private final OrderCodeGenerator orderCodes;
    private final Clock clock;
    private final String returnUrl;
    private final String cancelUrl;
    private final Map<Long, Instant> lastSynced = new ConcurrentHashMap<>();

    public PaymentService(PaymentOrderRepository orders, SubscriptionPlanRepository plans,
                          SubscriptionService subscriptionService, PayOsGateway payOs,
                          OrderCodeGenerator orderCodes, Clock clock,
                          @Value("${payos.return-url}") String returnUrl,
                          @Value("${payos.cancel-url}") String cancelUrl) {
        this.orders = orders; this.plans = plans; this.subscriptionService = subscriptionService;
        this.payOs = payOs; this.orderCodes = orderCodes; this.clock = clock;
        this.returnUrl = returnUrl; this.cancelUrl = cancelUrl;
    }

    @Transactional
    public PaymentOrderResponse checkout(Long userId, PlanCode planCode) {
        // The catalog row is a stable database mutex for this plan. It closes the
        // first-checkout race where no user/plan order exists yet, across app instances.
        SubscriptionPlan plan = plans.findByCodeAndActiveTrueForUpdate(planCode)
                .orElseThrow(() -> new AppException(ErrorCode.PLAN_NOT_FOUND));
        if (plan.getCode() == PlanCode.FREE || plan.getPrice() <= 0) {
            throw new AppException(ErrorCode.PLAN_NOT_PURCHASABLE);
        }
        // payOS decides whether an old link is still payable. Asking it first keeps a paid order whose
        // webhook never arrived from being handed out again as a QR code the bank rejects as already paid.
        for (PaymentOrder candidate : orders.findAllByUserIdAndPlanIdAndStatusOrderByCreatedAtDesc(
                userId, plan.getId(), PaymentStatus.PENDING)) {
            boolean wasPending = candidate.getStatus() == PaymentStatus.PENDING;
            PaymentOrder current = syncWithPayOs(candidate, true);
            if (wasPending && current.getStatus() == PaymentStatus.PAID) return response(current);
            if (isReusable(current)) return response(current);
        }

        PaymentOrder order = orders.save(PaymentOrder.builder().orderCode(orderCodes.next()).userId(userId)
                .plan(plan).amount(plan.getPrice()).status(PaymentStatus.PENDING).createdAt(clock.instant()).build());
        try {
            PaymentLinkResult link = payOs.createPaymentLink(order.getOrderCode(), order.getAmount(),
                    "VeggiePal " + plan.getCode(), returnUrl, cancelUrl);
            order.setPaymentLinkId(link.paymentLinkId());
            order.setCheckoutUrl(link.checkoutUrl());
            order.setQrCode(link.qrCode());
            order.setAccountName(link.accountName());
            order.setAccountNumber(link.accountNumber());
            order.setBin(link.bin());
            order.setDescription(link.description());
            order.setExpiredAt(link.expiredAt());
            return response(orders.save(order));
        } catch (PayOsOperationException exception) {
            throw new AppException(ErrorCode.PAYOS_UNAVAILABLE);
        }
    }

    @Transactional
    public PaymentOrderResponse cancel(Long userId, Long orderId) {
        PaymentOrder order = orders.findByIdAndUserIdForUpdate(orderId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.PAYMENT_ORDER_NOT_FOUND));
        if (order.getStatus() == PaymentStatus.CANCELLED) return response(order);
        if (order.getStatus() != PaymentStatus.PENDING) {
            throw new AppException(ErrorCode.PAYMENT_ORDER_NOT_CANCELLABLE);
        }

        PaymentCancellationResult result;
        try {
            result = payOs.cancelPaymentLink(order.getOrderCode(), "Cancelled by customer");
        } catch (PayOsOperationException exception) {
            throw new AppException(ErrorCode.PAYOS_UNAVAILABLE);
        }
        if (result == PaymentCancellationResult.PAID) {
            throw new AppException(ErrorCode.PAYMENT_ORDER_NOT_CANCELLABLE);
        }
        if (result != PaymentCancellationResult.CANCELLED) {
            throw new AppException(ErrorCode.PAYMENT_CANCELLATION_NOT_CONFIRMED);
        }
        order.setStatus(PaymentStatus.CANCELLED);
        return response(orders.save(order));
    }

    @Transactional
    public PaymentOrderResponse getOrder(Long userId, Long orderId) {
        PaymentOrder order = orders.findByIdAndUserId(orderId, userId)
                .orElseThrow(() -> new AppException(ErrorCode.PAYMENT_ORDER_NOT_FOUND));
        if (order.getStatus() == PaymentStatus.PENDING && syncDue(order.getId())) {
            order = syncWithPayOs(order, false);
            if (order.getStatus() != PaymentStatus.PENDING) lastSynced.remove(order.getId());
        }
        return response(order);
    }

    @Transactional(readOnly = true)
    public List<PaymentOrderResponse> history(Long userId) {
        return orders.findAllByUserIdOrderByCreatedAtDesc(userId).stream().map(this::response).toList();
    }

    @Transactional
    public void processWebhook(Object webhookBody) {
        VerifiedPayment payment;
        try { payment = payOs.verifyWebhook(webhookBody); }
        catch (PayOsOperationException exception) { throw new AppException(ErrorCode.PAYOS_WEBHOOK_INVALID); }
        if (payment.orderCode() == null) throw new AppException(ErrorCode.PAYOS_WEBHOOK_INVALID);
        if (!"00".equals(payment.code()) || !"VND".equalsIgnoreCase(payment.currency())) {
            throw new AppException(ErrorCode.PAYMENT_NOT_SUCCESSFUL);
        }
        PaymentOrder order = orders.findByOrderCodeForUpdate(payment.orderCode()).orElse(null);
        // payOS registers a webhook by sending a correctly signed probe whose synthetic
        // order does not exist locally. Verification succeeded, so acknowledge it without
        // changing payment or subscription state.
        if (order == null) return;
        if (order.getStatus() == PaymentStatus.PAID) return;
        if (order.getStatus() == PaymentStatus.CANCELLED) return;
        if (payment.amount() == null || payment.amount() != order.getAmount()) {
            throw new AppException(ErrorCode.PAYMENT_AMOUNT_MISMATCH);
        }
        if (order.getPaymentLinkId() != null && payment.paymentLinkId() != null
                && !order.getPaymentLinkId().equals(payment.paymentLinkId())) {
            throw new AppException(ErrorCode.PAYOS_WEBHOOK_INVALID);
        }
        markPaid(order, payment.reference());
    }

    private void markPaid(PaymentOrder order, String reference) {
        Instant paidAt = clock.instant();
        order.setStatus(PaymentStatus.PAID);
        order.setPaidAt(paidAt);
        if (reference != null) order.setPaymentReference(reference);
        orders.save(order);
        subscriptionService.activate(order.getUserId(), order.getPlan(), paidAt);
    }

    /**
     * Repairs a pending order from payOS, the source of truth for the link. A paid link activates the plan
     * exactly as the webhook does. With {@code closeDeadLink} a cancelled, expired or failed link closes the
     * order so checkout does not reuse it. A payOS outage leaves the order unchanged.
     */
    private PaymentOrder syncWithPayOs(PaymentOrder order, boolean closeDeadLink) {
        if (order.getStatus() != PaymentStatus.PENDING || order.getPaymentLinkId() == null) return order;
        // Same row lock as the webhook, so a late webhook cannot activate the plan a second time.
        PaymentOrder locked = orders.findByIdAndUserIdForUpdate(order.getId(), order.getUserId()).orElse(order);
        if (locked.getStatus() != PaymentStatus.PENDING) return locked;
        PaymentLinkState state;
        try {
            state = payOs.getPaymentLinkState(locked.getOrderCode());
        } catch (PayOsOperationException exception) {
            log.warn("Could not read payOS status of order {}", locked.getOrderCode(), exception);
            return locked;
        }
        if (state == PaymentLinkState.PAID) {
            markPaid(locked, null);
        } else if (state == PaymentLinkState.CLOSED && closeDeadLink) {
            locked.setStatus(PaymentStatus.CANCELLED);
            orders.save(locked);
        }
        return locked;
    }

    private boolean syncDue(Long orderId) {
        Instant now = clock.instant();
        Instant last = lastSynced.get(orderId);
        if (last != null && last.plus(SYNC_INTERVAL).isAfter(now)) return false;
        lastSynced.put(orderId, now);
        return true;
    }

    private PaymentOrderResponse response(PaymentOrder o) {
        boolean qrVisible = o.getStatus() == PaymentStatus.PENDING
                && (o.getExpiredAt() == null || o.getExpiredAt().isAfter(clock.instant()));
        return new PaymentOrderResponse(o.getId(), o.getOrderCode(), o.getPlan().getCode(), o.getAmount(),
                o.getStatus(), o.getCheckoutUrl(), qrVisible ? o.getQrCode() : null,
                o.getAccountName(), o.getAccountNumber(), o.getBin(), o.getDescription(), o.getExpiredAt(),
                o.getCreatedAt(), o.getPaidAt());
    }

    private boolean isReusable(PaymentOrder order) {
        return order.getStatus() == PaymentStatus.PENDING
                && (order.getExpiredAt() == null || order.getExpiredAt().isAfter(clock.instant()))
                && order.getPaymentLinkId() != null && order.getCheckoutUrl() != null && order.getQrCode() != null;
    }
}
