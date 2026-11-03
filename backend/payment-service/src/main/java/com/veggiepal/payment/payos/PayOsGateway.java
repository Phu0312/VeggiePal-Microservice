package com.veggiepal.payment.payos;

public interface PayOsGateway {
    PaymentLinkResult createPaymentLink(long orderCode, long amount, String description,
                                        String returnUrl, String cancelUrl);
    PaymentCancellationResult cancelPaymentLink(long orderCode, String reason);
    PaymentLinkState getPaymentLinkState(long orderCode);
    VerifiedPayment verifyWebhook(Object webhookBody);
}
