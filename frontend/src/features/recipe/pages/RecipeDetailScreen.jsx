import { useMemo } from "react";
import { Link, useLocation, useNavigate, useParams } from "react-router-dom";
import { ArrowLeft, ChefHat, Clock, Flame, Pencil, TriangleAlert, Users, Wheat } from "lucide-react";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { useAuthStore } from "@/features/auth/store/authStore";
import AuthorAvatar from "@/features/blog/components/AuthorAvatar";
import { FALLBACK_AUTHOR_NAME, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import StatusBadge from "@/features/my-content/components/StatusBadge";
import { getRecipeStatusInfo } from "@/features/my-content/utils/statusInfo";
import { useRecipe } from "@/features/recipe/hooks/useRecipes";
import { useRecipeNutrition } from "@/features/recipe/hooks/useRecipeNutrition";
import { formatIngredientAmount, sortSteps } from "@/features/recipe/utils/recipeFormat";
import {
  collectIngredientWarnings,
  isAllergenIngredient,
  isNonVeganIngredient,
} from "@/features/recipe/utils/recipeSafety";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";
import FallbackImage from "@/shared/components/FallbackImage";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Trang đọc một công thức (route /recipes/:recipeId), công khai với công thức đã đăng.
// BE chỉ trả bản nháp/đang ẩn cho tác giả hoặc ADMIN (kèm token), người khác nhận 404. FE vẫn kiểm tra
// thêm ở đây để chắc chắn không hiện nhầm (vd. công thức ARCHIVED, BE trả cho mọi người vì thực đơn cũ cần).
export default function RecipeDetailScreen() {
  const { recipeId } = useParams();
  const navigate = useNavigate();
  const location = useLocation();
  const user = useAuthStore((s) => s.user);

  const id = /^[1-9]\d*$/.test(recipeId ?? "") ? Number(recipeId) : null;
  const { data: recipe, isPending, isError } = useRecipe(id);
  const { data: authors } = usePublicUsers(recipe ? [recipe.userId] : []);
  const author = recipe ? authors?.get(recipe.userId) : undefined;
  const recipes = useMemo(() => (recipe ? [recipe] : []), [recipe]);
  const { nutritionById, gapById } = useRecipeNutrition(recipes);

  const canManage = Boolean(recipe && (recipe.userId === user?.id || user?.role === "ADMIN"));
  const visible = Boolean(recipe && (recipe.status === "PUBLISHED" || canManage));

  // Có lịch sử trong app thì quay lại, mở thẳng link thì về trang chủ.
  const goBack = () => (location.key !== "default" ? navigate(-1) : navigate("/"));

  let body;
  if (id === null || isError || (recipe && !visible)) {
    body = <NotFound />;
  } else if (isPending) {
    body = <ArticleSkeleton />;
  } else {
    body = (
      <RecipeArticle
        recipe={recipe}
        author={author}
        nutrition={nutritionById.get(recipe.id)}
        nutritionGap={gapById.get(recipe.id)}
        canManage={canManage}
        isLoggedIn={Boolean(user)}
      />
    );
  }

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-6">
        <div>
          <Button type="button" variant="ghost" size="sm" onClick={goBack}>
            <ArrowLeft className="size-4" />
            Quay lại
          </Button>
        </div>
        {body}
      </main>

      <AppFooter />
    </div>
  );
}

function RecipeArticle({ recipe, author, nutrition, nutritionGap, canManage, isLoggedIn }) {
  const steps = sortSteps(recipe.steps);
  const ingredients = recipe.ingredients ?? [];
  const warnings = collectIngredientWarnings(recipe);
  const showStatus = recipe.status !== "PUBLISHED";

  return (
    <article className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-8">
      <div className="flex items-center gap-3">
        <AuthorAvatar author={author} />
        <div className="min-w-0">
          <p className="truncate text-sm font-semibold text-ink">
            {author?.fullName ?? FALLBACK_AUTHOR_NAME}
          </p>
          <p className="text-xs text-subtle">
            {formatTimeAgo(recipe.publishedAt ?? recipe.createdAt)}
          </p>
        </div>
        <div className="ml-auto flex shrink-0 items-center gap-2">
          {showStatus && <StatusBadge info={getRecipeStatusInfo(recipe.status)} />}
          {canManage && (
            <Link
              to={`/recipes/${recipe.id}/edit`}
              className={buttonVariants({ variant: "outline", size: "sm" })}
            >
              <Pencil className="size-3.5" />
              Sửa
            </Link>
          )}
        </div>
      </div>

      <h1 className="mt-5 font-heading text-2xl font-bold leading-tight text-ink sm:text-4xl">
        {recipe.title}
      </h1>

      {recipe.description && (
        <p className="mt-3 whitespace-pre-line break-words text-base leading-relaxed text-body">
          {recipe.description}
        </p>
      )}

      <ul className="mt-4 flex flex-wrap gap-2 text-sm">
        {recipe.prepTime > 0 && <Chip icon={Clock}>Chuẩn bị {recipe.prepTime} phút</Chip>}
        {recipe.cookTime > 0 && <Chip icon={Clock}>Nấu {recipe.cookTime} phút</Chip>}
        <Chip icon={Users}>{recipe.servings} khẩu phần</Chip>
        <Chip icon={Flame}>
          {nutrition
            ? `${nutrition.kcal} kcal • ${nutrition.protein}g đạm / khẩu phần`
            : "Chưa có thông tin dinh dưỡng"}
        </Chip>
        {nutrition && (
          <Chip icon={Wheat}>{`${nutrition.carbs}g carb • ${nutrition.fat}g béo / khẩu phần`}</Chip>
        )}
      </ul>
      {!nutrition && nutritionGap && <p className="mt-2 text-xs text-subtle">{nutritionGap}</p>}

      <FallbackImage
        src={recipe.imageUrl}
        alt={recipe.title}
        className="mt-6 aspect-[16/9] w-full rounded-2xl object-cover"
        draggable={false}
        fallback={
          <div className="mt-6 grid aspect-[16/6] w-full place-items-center rounded-2xl bg-brand-soft text-brand">
            <ChefHat className="size-10" />
          </div>
        }
      />

      <section className="mt-8">
        <h2 className="font-heading text-xl font-bold text-ink">Nguyên liệu</h2>
        {warnings.allergens.length > 0 && (
          <Notice tone="warning">
            Có nguyên liệu thuộc nhóm dễ gây dị ứng: <strong>{warnings.allergens.join(", ")}</strong>.{" "}
            {isLoggedIn ? (
              <Link to="/profile/edit" className="font-semibold underline underline-offset-2">
                Kiểm tra hồ sơ dị ứng của bạn
              </Link>
            ) : (
              "Hãy đối chiếu với tình trạng dị ứng của bạn."
            )}
          </Notice>
        )}
        {warnings.nonVegan.length > 0 && (
          <Notice tone="danger">
            Có nguyên liệu không thuần chay: <strong>{warnings.nonVegan.join(", ")}</strong>.
          </Notice>
        )}
        <ul className="mt-3 divide-y divide-border rounded-2xl border border-border bg-surface">
          {ingredients.map((item) => (
            <li
              key={item.ingredientId}
              className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-0.5 px-4 py-2.5"
            >
              <span className="text-sm font-medium text-ink">
                {item.ingredientName}
                {item.note && <span className="font-normal text-subtle"> ({item.note})</span>}
                {isAllergenIngredient(item) && <Tag tone="warning">Dễ gây dị ứng</Tag>}
                {isNonVeganIngredient(item) && <Tag tone="danger">Không thuần chay</Tag>}
              </span>
              <span className="text-sm font-semibold text-brand">{formatIngredientAmount(item)}</span>
            </li>
          ))}
        </ul>
      </section>

      <section className="mt-8">
        <h2 className="font-heading text-xl font-bold text-ink">Cách làm</h2>
        <ol className="mt-3 space-y-4">
          {steps.map((step, index) => (
            <li key={step.stepNumber ?? index} className="flex gap-3">
              <span className="grid size-8 shrink-0 place-items-center rounded-full bg-brand text-sm font-bold text-brand-foreground">
                {index + 1}
              </span>
              <p className="min-w-0 flex-1 whitespace-pre-line break-words pt-1 text-base leading-relaxed text-body">
                {step.instruction}
              </p>
            </li>
          ))}
        </ol>
      </section>
    </article>
  );
}

const TONE_CLASSES = {
  warning: "bg-warning/15 text-warning",
  danger: "bg-destructive/10 text-destructive",
};

// Khung cảnh báo phía trên danh sách nguyên liệu.
function Notice({ tone, children }) {
  return (
    <p className={`mt-3 flex items-start gap-2 rounded-xl px-3 py-2 text-sm ${TONE_CLASSES[tone]}`}>
      <TriangleAlert className="mt-0.5 size-4 shrink-0" />
      <span>{children}</span>
    </p>
  );
}

// Nhãn nhỏ cạnh tên nguyên liệu.
function Tag({ tone, children }) {
  return (
    <span className={`ml-2 rounded-full px-2 py-0.5 align-middle text-[11px] font-medium ${TONE_CLASSES[tone]}`}>
      {children}
    </span>
  );
}

function Chip({ icon: Icon, children }) {
  return (
    <li className="flex items-center gap-1.5 rounded-full border border-border bg-surface px-3 py-1.5 text-body">
      <Icon className="size-4 text-brand" />
      {children}
    </li>
  );
}

function NotFound() {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center shadow-sm">
      <h1 className="font-heading text-xl font-bold text-ink">Không tìm thấy công thức</h1>
      <p className="mt-2 text-sm text-subtle">
        Công thức không tồn tại, chưa được đăng hoặc đã bị ẩn.
      </p>
      <Link
        to="/"
        className="mt-4 inline-block rounded-full bg-brand px-5 py-2 text-sm font-medium text-brand-foreground transition hover:opacity-90"
      >
        Về trang chủ
      </Link>
    </div>
  );
}

function ArticleSkeleton() {
  return (
    <div
      aria-hidden
      className="animate-pulse rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-8"
    >
      <div className="flex items-center gap-3">
        <div className="size-11 rounded-full bg-surface" />
        <div className="h-4 w-40 rounded bg-surface" />
      </div>
      <div className="mt-5 h-8 w-4/5 rounded bg-surface" />
      <div className="mt-4 flex gap-2">
        <div className="h-8 w-32 rounded-full bg-surface" />
        <div className="h-8 w-28 rounded-full bg-surface" />
      </div>
      <div className="mt-6 aspect-[16/9] w-full rounded-2xl bg-surface" />
      <div className="mt-8 space-y-3">
        <div className="h-4 w-full rounded bg-surface" />
        <div className="h-4 w-full rounded bg-surface" />
        <div className="h-4 w-2/3 rounded bg-surface" />
      </div>
    </div>
  );
}
