export const PENDING_ORDER_STORAGE_KEY = "veggiepal_pending_order_id";

/**
 * Định dạng số tiền VNĐ (vd: 29.000đ).
 */
export function formatVnd(amount) {
  if (amount == null) return "0đ";
  return `${Number(amount).toLocaleString("vi-VN")}đ`;
}

/**
 * Định dạng ngày giờ chuẩn Việt Nam (vd: 14:30 21/10/2026).
 */
export function formatDateTime(isoString) {
  if (!isoString) return "—";
  try {
    const d = new Date(isoString);
    if (Number.isNaN(d.getTime())) return "—";
    return new Intl.DateTimeFormat("vi-VN", {
      dateStyle: "short",
      timeStyle: "short",
    }).format(d);
  } catch {
    return "—";
  }
}

/**
 * Định dạng ngày (vd: 21/10/2026).
 */
export function formatDate(isoString) {
  if (!isoString) return "—";
  try {
    const d = new Date(isoString);
    if (Number.isNaN(d.getTime())) return "—";
    return new Intl.DateTimeFormat("vi-VN", {
      dateStyle: "short",
    }).format(d);
  } catch {
    return "—";
  }
}

/**
 * Thông tin trạng thái đơn hàng:
 * Nhãn tiếng Việt và màu sắc dịu nhẹ (đặc biệt PENDING là "Chưa thanh toán" không quá gay gắt).
 */
export function getPaymentStatusInfo(status) {
  switch (status) {
    case "PAID":
      return {
        label: "Đã thanh toán",
        variant: "success",
        className:
          "border-emerald-500/30 bg-emerald-500/10 text-emerald-700 dark:text-emerald-400",
      };
    case "PENDING":
      return {
        label: "Chưa thanh toán",
        variant: "pending",
        className:
          "border-amber-500/30 bg-amber-500/10 text-amber-700 dark:text-amber-400",
      };
    case "CANCELLED":
      return {
        label: "Đã huỷ",
        variant: "cancelled",
        className: "border-border bg-surface text-subtle",
      };
    case "FAILED":
      return {
        label: "Thất bại",
        variant: "failed",
        className:
          "border-destructive/30 bg-destructive/10 text-destructive",
      };
    default:
      return {
        label: status || "Không rõ",
        variant: "unknown",
        className: "border-border bg-surface text-subtle",
      };
  }
}

/**
 * Đơn PENDING còn hạn (chưa quá expiredAt) -> có thể tiếp tục thanh toán.
 */
export function isOrderResumable(order) {
  if (!order || order.status !== "PENDING") return false;
  if (!order.expiredAt) return false;
  return new Date(order.expiredAt).getTime() > Date.now();
}

/**
 * Tra tên ngân hàng từ mã BIN (các ngân hàng VietQR phổ biến).
 */
const BANK_NAMES = {
  970415: "VietinBank",
  970436: "Vietcombank",
  970418: "BIDV",
  970405: "Agribank",
  970422: "MB Bank",
  970407: "Techcombank",
  970416: "ACB",
  970432: "VPBank",
  970423: "TPBank",
  970403: "Sacombank",
  970437: "HDBank",
  970441: "VIB",
  970443: "SHB",
  970448: "OCB",
  970426: "MSB",
  970431: "Eximbank",
  970454: "Viet Capital Bank",
  970429: "SCB",
  970440: "SeABank",
  970452: "KienlongBank",
  970414: "Oceanbank",
  970425: "ABBank",
  970419: "NCB",
  970428: "Nam A Bank",
  970449: "LPBank",
  970438: "BaoViet Bank",
  970400: "SaigonBank",
  970412: "PVcomBank",
  970409: "BacABank",
  970427: "VietABank",
  970433: "VietBank",
  970446: "COOPBANK",
  970424: "Shinhan Bank",
  970434: "Indovina Bank",
  546034: "CAKE by VPBank",
  546035: "Ubank by VPBank",
  963388: "Timo",
  971005: "Viettel Money",
  971011: "VNPT Money",
};

export function getBankName(bin) {
  if (bin == null || bin === "") return "—";
  return BANK_NAMES[String(bin)] ?? `Ngân hàng (BIN ${bin})`;
}

/**
 * Tên và badge hiển thị của các gói.
 */
export const PLAN_DETAILS = {
  FREE: {
    name: "Gói Khám Phá",
    code: "FREE",
    badgeLabel: "Miễn phí",
    popular: false,
    gradient: "from-slate-500 to-slate-700",
  },
  PLUS: {
    name: "Gói Plus",
    code: "PLUS",
    badgeLabel: "Phổ biến nhất",
    popular: true,
    gradient: "from-brand to-brand-2",
  },
  PRO: {
    name: "Gói Pro Chuyên Sâu",
    code: "PRO",
    badgeLabel: "Toàn năng",
    popular: false,
    gradient: "from-amber-500 to-orange-600",
  },
};
