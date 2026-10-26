import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  createMealPlan,
  editMealPlan,
  favoriteMealPlan,
  replaceMeal,
  unfavoriteMealPlan,
  updatePlanFromHealth,
} from "@/features/meal-planner/api/mealPlanApi";
import { mealPlanKeys } from "@/features/meal-planner/queryKeys";
import { replacePlanInList, setPlanFavorite } from "@/features/meal-planner/utils/mealPlan";

/**
 * Tạo thực đơn mới. mutate(payload) -> MealPlan.
 * Thực đơn mới được đặt lên đầu danh sách cache (BE sắp mới nhất trước) nên không cần tải lại.
 */
export function useCreateMealPlan() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: createMealPlan,
    onSuccess: (created) => {
      queryClient.setQueryData(mealPlanKeys.list, (old) => [
        created,
        ...(Array.isArray(old) ? old.filter((plan) => plan.id !== created.id) : []),
      ]);
    },
  });
}

/**
 * Yêu thích / bỏ yêu thích cả thực đơn. mutate({ planId, favorite }) với favorite = true | false.
 * Thành công thì ghi cờ `isFavorite` thẳng vào danh sách đã cache, không cần tải lại.
 */
export function useSetPlanFavorite() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ planId, favorite }) => (favorite ? favoriteMealPlan(planId) : unfavoriteMealPlan(planId)),
    onSuccess: (_data, { planId, favorite }) => {
      queryClient.setQueryData(mealPlanKeys.list, (old) => setPlanFavorite(old, planId, favorite));
      // Danh sách yêu thích (hộp thoại "Yêu thích của tôi") đã đổi nên bỏ cache để lần mở sau lấy lại.
      queryClient.invalidateQueries({ queryKey: mealPlanKeys.favoritesRoot });
    },
  });
}

/**
 * Xem trước thực đơn sau khi cập nhật theo chỉ số sức khỏe (không lưu).
 * mutate({ planId, customTarget? }) -> kết quả xem trước. customTarget là mục tiêu tự đặt (bỏ trống = BE tự tính).
 */
export function usePreviewHealthUpdate() {
  return useMutation({
    mutationFn: ({ planId, customTarget }) => updatePlanFromHealth(planId, { confirm: false, customTarget }),
  });
}

/**
 * Lưu bản cập nhật theo chỉ số sức khỏe. mutate({ planId, customTarget?, changeSummary? }); phải dùng cùng customTarget
 * với bản xem trước người dùng vừa thấy. Thành công thì thay thực đơn trong cache bằng bản mới.
 */
export function useApplyHealthUpdate() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ planId, customTarget, changeSummary }) =>
      updatePlanFromHealth(planId, { confirm: true, customTarget, changeSummary }),
    onSuccess: (result, { planId }) => {
      if (!result?.updatedMealPlan) return;
      queryClient.setQueryData(mealPlanKeys.list, (old) => replacePlanInList(old, result.updatedMealPlan));
      // Bản trước đó vừa được BE lưu vào lịch sử phiên bản.
      queryClient.invalidateQueries({ queryKey: mealPlanKeys.versions(planId) });
    },
  });
}

/** Xem trước chỉnh sửa thủ công (không lưu). mutate({ planId, edits }) -> { plan } sau khi áp dụng thử. */
export function usePreviewMealEdit() {
  return useMutation({
    mutationFn: ({ planId, edits }) => editMealPlan(planId, { edits, preview: true }),
  });
}

/** Lưu chỉnh sửa thủ công. mutate({ planId, edits, changeSummary }); thành công thì thay thực đơn trong cache. */
export function useSaveMealEdit() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ planId, edits, changeSummary }) => editMealPlan(planId, { edits, changeSummary, preview: false }),
    onSuccess: (result, { planId }) => {
      if (!result?.updatedMealPlan) return;
      queryClient.setQueryData(mealPlanKeys.list, (old) => replacePlanInList(old, result.updatedMealPlan));
      queryClient.invalidateQueries({ queryKey: mealPlanKeys.versions(planId) });
    },
  });
}

/** Đổi một món. mutate({ planId, day, mealType, currentRecipeId }) -> MealPlan sau khi cập nhật. */
export function useReplaceMeal() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ planId, ...body }) => replaceMeal(planId, body),
    onSuccess: (updated) => {
      queryClient.setQueryData(mealPlanKeys.list, (old) => replacePlanInList(old, updated));
    },
  });
}
