import { useEffect, useRef, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { ChefHat, Loader2, Plus, Search, Soup, Timer, X } from "lucide-react";

import { Button } from "@/components/ui/button";
import RecipeCard, { RecipeCardSkeleton } from "@/features/recipe/components/RecipeCard";
import { useRecipeNutrition } from "@/features/recipe/hooks/useRecipeNutrition";
import { useRecipeFeed } from "@/features/recipe/hooks/useRecipes";
import AppHeader from "@/shared/components/AppHeader";
import GlassBanner, { GlassChip, GlassPanel } from "@/shared/components/GlassBanner";
import Reveal from "@/shared/components/Reveal";
import { useContentForm } from "@/shared/hooks/useContentForm";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

const PAGE_SIZE = 12;
const SEARCH_DEBOUNCE_MS = 400;

// Trang duyệt công thức (route /recipes), công khai: lưới công thức đã đăng, mới nhất trước,
// tìm theo từ khóa (BE tìm trong tên và mô tả). Từ khóa nằm trên URL (?q=) để chia sẻ/quay lại được.
export default function RecipeListScreen() {
  const [searchParams, setSearchParams] = useSearchParams();
  const { openForm } = useContentForm();
  const keyword = (searchParams.get("q") ?? "").trim();

  const [text, setText] = useState(keyword);
  const timerRef = useRef(undefined);
  useEffect(() => () => clearTimeout(timerRef.current), []);

  const pushKeyword = (value) => {
    clearTimeout(timerRef.current);
    const next = value.trim();
    // replace: gõ tìm kiếm không nên làm đầy lịch sử trình duyệt.
    setSearchParams(next ? { q: next } : {}, { replace: true });
  };

  const handleChange = (event) => {
    const value = event.target.value;
    setText(value);
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => pushKeyword(value), SEARCH_DEBOUNCE_MS);
  };

  const handleSubmit = (event) => {
    event.preventDefault();
    pushKeyword(text);
  };

  const handleClear = () => {
    setText("");
    pushKeyword("");
  };

  const { recipes, total, isPending, isError, error, hasNextPage, fetchNextPage, isFetchingNextPage } =
    useRecipeFeed({ keyword, size: PAGE_SIZE });
  const { nutritionById } = useRecipeNutrition(recipes);
  const { data: authors } = usePublicUsers(recipes.map((r) => r.userId));

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 py-6">
        <GlassBanner>
          <div className="flex flex-col gap-6 lg:flex-row lg:items-center lg:justify-between lg:gap-12">
            <div className="flex max-w-2xl flex-col items-start gap-4">
              <GlassChip icon={ChefHat}>Công thức</GlassChip>
              <h1 className="font-heading text-3xl font-extrabold leading-tight text-ink sm:text-4xl">
                Công Thức <span className="text-gradient-brand">Món Chay</span>
              </h1>
              <p className="max-w-md text-sm leading-relaxed text-body sm:text-base">
                Khám phá những món chay thanh lành do cộng đồng VeggiePal chia sẻ, từ bữa sáng nhẹ nhàng
                đến mâm cơm đủ đầy.
              </p>
              {/* Mở popup; khách chưa đăng nhập được đưa sang trang đăng nhập rồi quay lại. */}
              <Button
                type="button"
                variant="gradient"
                size="md"
                className="shadow-md"
                onClick={() => openForm("recipe")}
              >
                <Plus className="size-4" />
                Chia sẻ công thức
              </Button>
            </div>

            <GlassPanel className="flex w-full max-w-sm items-center gap-4">
              <span className="grid size-16 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-md">
                <Soup className="size-9" strokeWidth={1.6} />
              </span>
              <div className="min-w-0">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-subtle">
                  Kho công thức
                </p>
                <p className="font-heading text-base font-bold text-ink">
                  {isPending || isError
                    ? "VeggiePal"
                    : keyword
                      ? `${total} kết quả cho “${keyword}”`
                      : `${total} công thức đã đăng`}
                </p>
                <p className="flex items-center gap-1 text-xs text-subtle">
                  <Timer className="size-3.5" />
                  Mới nhất hiển thị trước
                </p>
              </div>
            </GlassPanel>
          </div>
        </GlassBanner>

        <form onSubmit={handleSubmit} role="search" className="relative">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-subtle" />
          <input
            type="search"
            value={text}
            onChange={handleChange}
            placeholder="Tìm công thức theo tên hoặc mô tả..."
            aria-label="Tìm công thức"
            className="glass-strong h-11 w-full rounded-full pl-10 pr-10 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 [&::-webkit-search-cancel-button]:hidden"
          />
          {text && (
            <button
              type="button"
              onClick={handleClear}
              aria-label="Xóa từ khóa"
              className="absolute right-3 top-1/2 grid size-6 -translate-y-1/2 place-items-center rounded-full text-subtle transition hover:bg-surface hover:text-ink"
            >
              <X className="size-4" />
            </button>
          )}
        </form>

        {isError ? (
          <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {error.message}
          </p>
        ) : isPending ? (
          <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {Array.from({ length: 6 }, (_, i) => (
              <RecipeCardSkeleton key={i} />
            ))}
          </div>
        ) : recipes.length === 0 ? (
          <div className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
            {keyword ? (
              <>
                <p>Không tìm thấy công thức nào phù hợp với “{keyword}”.</p>
                <Button type="button" variant="outline" size="sm" className="mt-3" onClick={handleClear}>
                  Xóa từ khóa
                </Button>
              </>
            ) : (
              <p>Chưa có công thức nào được đăng.</p>
            )}
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {recipes.map((recipe) => (
                <Reveal key={recipe.id}>
                  <RecipeCard
                    recipe={recipe}
                    nutrition={nutritionById.get(recipe.id)}
                    author={authors?.get(recipe.userId)}
                  />
                </Reveal>
              ))}
            </div>

            {hasNextPage && (
              <Button
                type="button"
                variant="outline"
                className="self-center"
                disabled={isFetchingNextPage}
                onClick={() => fetchNextPage()}
              >
                {isFetchingNextPage ? (
                  <>
                    <Loader2 className="size-4 animate-spin" />
                    Đang tải...
                  </>
                ) : (
                  "Xem thêm công thức"
                )}
              </Button>
            )}
          </>
        )}
      </main>

    </div>
  );
}
