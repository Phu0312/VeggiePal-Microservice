import { Link } from "react-router-dom";
import { BookOpen, ChefHat, Sparkles } from "lucide-react";

import FallbackImage from "@/shared/components/FallbackImage";
import { cn } from "@/lib/utils";

/**
 * Card hiển thị một mục nội dung gợi ý từ AI (có thể là BLOG hoặc RECIPE).
 * Hiển thị hình ảnh, badge loại, lý do AI gợi ý (reason) và tiêu đề.
 */
export default function RecommendationCard({ item }) {
  const isRecipe = item.type === "RECIPE";
  const content = item.content || {};

  const title = content.title || "Nội dung ẩm thực chay";
  const imageUrl = isRecipe ? content.imageUrl : (content.thumbnailUrl || content.imageUrl);
  const linkPath = isRecipe ? `/recipes/${item.id}` : `/blog/${item.id}`;

  return (
    <article className="group flex flex-col overflow-hidden rounded-2xl border border-border bg-card transition hover:border-brand/40 hover:shadow-md">
      <div className="relative aspect-[16/10] w-full overflow-hidden bg-surface">
        <Link to={linkPath} tabIndex={-1} aria-hidden="true" className="block h-full w-full">
          <FallbackImage
            src={imageUrl}
            alt={title}
            className="h-full w-full object-cover transition duration-300 group-hover:scale-105"
            draggable={false}
            fallback={
              <div className="grid h-full w-full place-items-center bg-brand-soft text-brand">
                {isRecipe ? <ChefHat className="size-10" /> : <BookOpen className="size-10" />}
              </div>
            }
          />
        </Link>

        {/* Badge loại nội dung */}
        <span
          className={cn(
            "pointer-events-none absolute left-3 top-3 inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[11px] font-semibold backdrop-blur",
            isRecipe
              ? "bg-brand/90 text-brand-foreground"
              : "bg-blue-600/90 text-white"
          )}
        >
          {isRecipe ? <ChefHat className="size-3" /> : <BookOpen className="size-3" />}
          {isRecipe ? "Công thức" : "Bài viết"}
        </span>
      </div>

      <div className="flex flex-1 flex-col p-4">
        {/* Lý do AI gợi ý */}
        {item.reason && (
          <div className="mb-2 flex items-start gap-1.5 rounded-lg bg-brand-soft px-2.5 py-1.5 text-xs text-brand">
            <Sparkles className="size-3.5 shrink-0 translate-y-0.5" />
            <p className="line-clamp-2 leading-relaxed">{item.reason}</p>
          </div>
        )}

        {/* Tiêu đề */}
        <h3 className="line-clamp-2 font-heading text-base font-bold text-ink">
          <Link to={linkPath} className="transition hover:text-brand">
            {title}
          </Link>
        </h3>
      </div>
    </article>
  );
}
