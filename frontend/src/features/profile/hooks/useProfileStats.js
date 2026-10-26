import { useLatestHealthRecord } from "@/features/profile/hooks/useHealthRecords";
import { useMyBlogs } from "@/features/blog/hooks/useMyBlogs";
import { useMyRecipes } from "@/features/recipe/hooks/useMyRecipes";

/**
 * Số liệu thật cho trang hồ sơ: tổng bài viết (GET /blogs/me), tổng công thức
 * (GET /recipes/me) và chỉ số sức khỏe mới nhất. size=1 vì chỉ cần `totalElements`.
 */
export function useProfileStats() {
  const blogs = useMyBlogs({ size: 1 });
  const recipes = useMyRecipes({ size: 1 });
  const latest = useLatestHealthRecord();

  return {
    blogTotal: blogs.total,
    recipeTotal: recipes.total,
    latest: latest.data ?? null,
    loading: blogs.isPending || recipes.isPending || latest.isPending,
  };
}
