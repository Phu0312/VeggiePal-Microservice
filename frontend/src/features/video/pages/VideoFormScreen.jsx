import { Link, useLocation, useParams } from "react-router-dom";

import { useAuthStore } from "@/features/auth/store/authStore";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { flattenCategories } from "@/features/blog/utils/feedFilters";
import VideoForm from "@/features/video/components/VideoForm";
import { useVideo } from "@/features/video/hooks/useVideos";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";

// Trang đăng video mới (/videos/new) và sửa video (/videos/:videoId/edit), cần đăng nhập.
export default function VideoFormScreen() {
  const { videoId } = useParams();
  const location = useLocation();
  const isEdit = videoId !== undefined;
  const id = /^[1-9]\d*$/.test(videoId ?? "") ? Number(videoId) : null;

  const user = useAuthStore((s) => s.user);
  const {
    data: categoryTree,
    isPending: categoriesPending,
    isError: categoriesError,
  } = useCategories();

  // Nạp video để sửa: ưu tiên lấy từ router state (để sửa được cả bản nháp/bị từ chối từ My Content),
  // nếu không có thì gọi GET /videos/:id (chỉ video đã đăng).
  const stateVideo = location.state?.video;
  const shouldFetch = isEdit && !stateVideo && id !== null;
  const {
    data: fetchedVideo,
    isPending: videoPending,
    isError: videoError,
  } = useVideo(shouldFetch ? id : null);

  const video = stateVideo ?? fetchedVideo;
  const canEdit =
    !isEdit ||
    (video && (video.authorId === user?.id || user?.role === "ADMIN"));

  let body;
  if (isEdit && id === null) {
    body = (
      <Notice title="Video không hợp lệ">
        Đường dẫn video không đúng định dạng.
      </Notice>
    );
  } else if (isEdit && !stateVideo && videoError) {
    body = (
      <Notice title="Không mở được video này để sửa">
        Hiện chỉ mở trực tiếp được video đã đăng, hoặc bạn có thể mở từ mục “Nội dung của tôi”.
      </Notice>
    );
  } else if (isEdit && !videoPending && !canEdit) {
    body = (
      <Notice title="Bạn không có quyền sửa video này">
        Chỉ tác giả hoặc quản trị viên mới sửa được video này.
      </Notice>
    );
  } else if (categoriesError) {
    body = (
      <Notice title="Không tải được danh mục">
        Vui lòng tải lại trang và thử lại.
      </Notice>
    );
  } else if (categoriesPending || (isEdit && !video && videoPending)) {
    body = <FormSkeleton />;
  } else {
    body = (
      <VideoForm
        video={isEdit ? video : undefined}
        categories={flattenCategories(categoryTree)}
      />
    );
  }

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-6">
        <h1 className="font-heading text-3xl font-bold text-ink">
          {isEdit ? "Chỉnh sửa video" : "Đăng video nấu ăn"}
        </h1>
        {body}
      </main>

      <AppFooter />
    </div>
  );
}

function Notice({ title, children }) {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center shadow-sm">
      <h2 className="font-heading text-xl font-bold text-ink">{title}</h2>
      <p className="mt-2 text-sm text-subtle">{children}</p>
      <Link
        to="/my-content?tab=videos"
        className="mt-4 inline-block rounded-full bg-brand px-5 py-2 text-sm font-medium text-brand-foreground transition hover:opacity-90"
      >
        Về nội dung của tôi
      </Link>
    </div>
  );
}

function FormSkeleton() {
  return (
    <div
      aria-hidden
      className="animate-pulse space-y-5 rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6"
    >
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="aspect-video w-full rounded-2xl bg-surface" />
      <div className="h-32 w-full rounded-xl bg-surface" />
    </div>
  );
}
