/**
 * React Query keys dành riêng cho tính năng payment & subscriptions.
 */
export const paymentKeys = {
  all: ["payment"],
  plans: () => [...paymentKeys.all, "plans"],
  subscription: () => [...paymentKeys.all, "subscription", "me"],
  history: () => [...paymentKeys.all, "history"],
  order: (id) => [...paymentKeys.all, "order", String(id)],
  // Hạn mức AI đã dùng / còn lại (ai-service GET /ai/quotas/me).
  quotas: () => ["ai", "quotas", "me"],
};
