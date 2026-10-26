import { Sparkles, ArrowRight, AlertTriangle, RefreshCw } from "lucide-react";
import { Link } from "react-router-dom";
import { useQueryClient } from "@tanstack/react-query";

import { selectIsAuthenticated, useAuthStore } from "@/features/auth/store/authStore";
import RecommendationCard from "@/features/home/components/RecommendationCard";
import { useRecommendations } from "@/features/home/hooks/useRecommendations";
import { recommendationKeys } from "@/features/home/queryKeys";
import Reveal from "@/shared/components/Reveal";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { Button } from "@/components/ui/button";

/**
 * Khối "Gợi ý dành riêng cho bạn" trên trang chủ:
 * Sử dụng GET /ai/recommendations của ai-service.
 * - Đã đăng nhập: lấy danh sách các món ăn & bài viết AI đề xuất kèm lý do.
 * - Chưa đăng nhập: hiển thị banner giới thiệu đăng nhập để cá nhân hóa nội dung.
 * - Có xử lý riêng biệt lỗi Server (isError) và trạng thái rỗng.
 */
export default function AiRecommendationsSection() {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const queryClient = useQueryClient();
  const {
    data: recommendations = [],
    isPending,
    isError,
    error,
    isFetching,
  } = useRecommendations({ limit: 6 });

  const handleRetry = () => {
    queryClient.invalidateQueries({ queryKey: recommendationKeys.all });
  };

  return (
    <section className="border-t border-border bg-surface/30 px-6 py-16 font-sans md:px-12 lg:px-16">
      <div className="mx-auto max-w-6xl">
        <Reveal>
          <div className="flex flex-wrap items-end justify-between gap-4">
            <div>
              <p className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-brand">
                <Sparkles className="size-3.5" />
                Cá Nhân Hóa Bằng AI
              </p>
              <h2 className="mt-2 text-2xl font-bold text-ink sm:text-3xl">
                Gợi ý dành riêng cho bạn
              </h2>
              <p className="mt-1 text-sm text-subtle">
                Trí tuệ nhân tạo chọn lọc những công thức và bài viết chay phù hợp nhất với khẩu vị của bạn.
              </p>
            </div>

            {isAuthenticated && (
              <Link
                to="/recipes"
                className="hidden items-center gap-1 text-sm font-semibold text-brand transition hover:underline sm:inline-flex"
              >
                Khám phá thêm công thức
                <ArrowRight className="size-4" />
              </Link>
            )}
          </div>
        </Reveal>

        {!isAuthenticated ? (
          /* Banner CTA khi chưa đăng nhập */
          <div className="mt-8 rounded-3xl border border-dashed border-border bg-card p-8 text-center sm:p-12">
            <div className="mx-auto grid size-12 place-items-center rounded-full bg-brand-soft text-brand">
              <Sparkles className="size-6" />
            </div>
            <h3 className="mt-4 font-heading text-xl font-bold text-ink">
              Mở khóa gợi ý dinh dưỡng thông minh
            </h3>
            <p className="mx-auto mt-2 max-w-md text-sm text-subtle">
              Đăng nhập ngay để AI phân tích sở thích và thói quen ăn chay của bạn, từ đó đề xuất thực đơn và bài viết phù hợp nhất mỗi ngày.
            </p>
            <div className="mt-6">
              <Link
                to="/login"
                className={buttonVariants({ variant: "default", size: "md" })}
              >
                Đăng nhập để nhận gợi ý
              </Link>
            </div>
          </div>
        ) : isPending ? (
          /* Skeleton loading */
          <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {[0, 1, 2].map((i) => (
              <div
                key={i}
                className="h-72 animate-pulse rounded-2xl border border-border bg-card"
              />
            ))}
          </div>
        ) : isError ? (
          /* Trạng thái lỗi từ Backend kèm nút Thử lại */
          <div className="mt-8 flex flex-col items-center justify-center rounded-2xl border border-destructive/20 bg-destructive/5 p-6 text-center">
            <AlertTriangle className="size-8 text-destructive" />
            <p className="mt-2 text-sm font-medium text-destructive">
              {error?.message || "Không thể tải danh sách gợi ý AI lúc này."}
            </p>
            <Button
              type="button"
              variant="outline"
              size="sm"
              disabled={isFetching}
              onClick={handleRetry}
              className="mt-4 gap-1.5"
            >
              <RefreshCw className={`size-3.5 ${isFetching ? "animate-spin" : ""}`} />
              Thử lại
            </Button>
          </div>
        ) : recommendations.length === 0 ? (
          /* Trạng thái rỗng khi chưa có đủ dữ liệu */
          <div className="mt-8 rounded-2xl border border-border bg-card p-6 text-center text-sm text-subtle">
            Hiện tại chưa có đủ dữ liệu gợi ý mới. Hãy thử xem qua danh sách công thức thịnh hành bên trên!
          </div>
        ) : (
          /* Danh sách card gợi ý trực tiếp từ API */
          <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
            {recommendations.map((item, index) => (
              <Reveal key={`${item.type}-${item.id}`} delay={index * 100}>
                <RecommendationCard item={item} />
              </Reveal>
            ))}
          </div>
        )}
      </div>
    </section>
  );
}
