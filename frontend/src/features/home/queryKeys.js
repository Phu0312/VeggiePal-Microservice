// Khóa cache React Query cho tính năng AI Recommendations.
export const recommendationKeys = {
  all: ["ai", "recommendations"],
  list: ({ interest, limit }) => ["ai", "recommendations", { interest: interest || "default", limit }],
};
