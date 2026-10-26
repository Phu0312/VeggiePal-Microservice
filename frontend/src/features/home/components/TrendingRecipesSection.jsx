import { TrendingUp } from "lucide-react";

import RecipeCard, { RecipeCardSkeleton } from "@/features/recipe/components/RecipeCard";
import { useRecipeNutrition } from "@/features/recipe/hooks/useRecipeNutrition";
import { useRecipes } from "@/features/recipe/hooks/useRecipes";
import Reveal from "@/shared/components/Reveal";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Số công thức hiển thị ở trang chủ (BE chưa có xếp hạng "được yêu thích" nên lấy mới nhất).
const TRENDING_COUNT = 3;

export default function TrendingRecipesSection() {
  const { data, isPending, isError, error } = useRecipes({ size: TRENDING_COUNT });
  const recipes = data?.content;

  const { nutritionById } = useRecipeNutrition(recipes);
  const { data: authors } = usePublicUsers(recipes?.map((r) => r.userId));

  return (
    <section className="bg-background px-6 py-16 font-sans md:px-12 lg:px-16">
      <div className="mx-auto max-w-6xl">
        <Reveal>
          <p className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-brand">
            <TrendingUp className="h-3.5 w-3.5" />
            Xu Hướng Tuần Này
          </p>
          <h2 className="mt-2 text-2xl font-bold text-ink sm:text-3xl">
            Món chay được yêu thích nhất
          </h2>
        </Reveal>

        {isError ? (
          <p className="mt-8 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error.message}
          </p>
        ) : isPending ? (
          <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: TRENDING_COUNT }, (_, i) => (
              <RecipeCardSkeleton key={i} />
            ))}
          </div>
        ) : recipes.length === 0 ? (
          <p className="mt-8 text-sm text-subtle">Chưa có công thức nào được đăng.</p>
        ) : (
          <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {recipes.map((recipe, index) => (
              <Reveal key={recipe.id} delay={index * 100}>
                <RecipeCard
                  recipe={recipe}
                  nutrition={nutritionById.get(recipe.id)}
                  author={authors?.get(recipe.userId)}
                />
              </Reveal>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
