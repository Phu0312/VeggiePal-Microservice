import { keepPreviousData, useQuery } from "@tanstack/react-query";

import {
  getFavoriteMealPlan,
  getFavoriteMealPlans,
  getMealPlan,
  getMealPlanVersion,
  getMealPlans,
  getMealPlanVersions,
  getNutritionTarget,
} from "@/features/meal-planner/api/mealPlanApi";
import { mealPlanKeys } from "@/features/meal-planner/queryKeys";

/** Các thực đơn đã lưu của tôi, mới nhất trước (GET /ai/meal-plans). */
export function useMealPlans() {
  return useQuery({
    queryKey: mealPlanKeys.list,
    queryFn: getMealPlans,
    staleTime: 60 * 1000,
  });
}

/**
 * Mục tiêu calo / macro BE tính cho một `goalType` (GET /ai/meal-plans/nutrition-target). Chỉ tải khi `enabled`
 * và có goalType. Không thử lại khi lỗi (lỗi 6010 / 6020 / 6021 là do hồ sơ, thử lại cũng không khác) và luôn lấy
 * mới khi mở lại vì người dùng có thể vừa cập nhật hồ sơ.
 */
export function useNutritionTarget(goalType, enabled = true) {
  return useQuery({
    queryKey: mealPlanKeys.nutritionTarget(goalType),
    queryFn: () => getNutritionTarget(goalType),
    enabled: Boolean(enabled) && Boolean(goalType),
    staleTime: 0,
    retry: false,
  });
}

/**
 * Các phiên bản cũ của một thực đơn (GET /ai/meal-plans/:id/versions). Chỉ tải khi `enabled`
 * (hộp thoại lịch sử đang mở) và luôn lấy mới khi mở lại, vì có thể vừa có bản cũ mới được lưu.
 */
export function useMealPlanVersions(planId, enabled) {
  return useQuery({
    queryKey: mealPlanKeys.versions(planId),
    queryFn: () => getMealPlanVersions(planId),
    enabled: Boolean(enabled) && planId != null,
    staleTime: 0,
  });
}

/**
 * Một thực đơn lấy mới từ server (GET /ai/meal-plans/:id). Chỉ tải khi `enabled` và luôn lấy mới khi mở lại,
 * dùng để đối chiếu phiên bản hiện tại với các bản cũ trong hộp thoại lịch sử.
 */
export function useMealPlan(planId, enabled) {
  return useQuery({
    queryKey: mealPlanKeys.detail(planId),
    queryFn: () => getMealPlan(planId),
    enabled: Boolean(enabled) && planId != null,
    staleTime: 0,
  });
}

/** Nội dung đầy đủ của một phiên bản cũ (GET /ai/meal-plans/:id/versions/:version), chỉ tải khi `enabled`. */
export function useMealPlanVersion(planId, version, enabled) {
  return useQuery({
    queryKey: mealPlanKeys.version(planId, version),
    queryFn: () => getMealPlanVersion(planId, version),
    enabled: Boolean(enabled) && planId != null && version != null,
    // Phiên bản cũ không đổi sau khi được lưu nên giữ cache lâu.
    staleTime: 5 * 60 * 1000,
  });
}

/**
 * Một trang thực đơn yêu thích (GET /ai/meal-plans/favorites). Chỉ tải khi `enabled` (hộp thoại đang mở),
 * luôn lấy mới khi mở lại vì người dùng có thể vừa bật / tắt yêu thích.
 */
export function useFavoriteMealPlans(page, size, enabled) {
  return useQuery({
    queryKey: mealPlanKeys.favorites(page),
    queryFn: () => getFavoriteMealPlans({ page, size }),
    enabled: Boolean(enabled),
    staleTime: 0,
    placeholderData: keepPreviousData,
  });
}

/** Một thực đơn yêu thích (GET /ai/meal-plans/favorites/:id), chỉ tải khi `enabled` (mục đang được mở xem). */
export function useFavoriteMealPlan(planId, enabled) {
  return useQuery({
    queryKey: mealPlanKeys.favorite(planId),
    queryFn: () => getFavoriteMealPlan(planId),
    enabled: Boolean(enabled) && planId != null,
    staleTime: 0,
  });
}
