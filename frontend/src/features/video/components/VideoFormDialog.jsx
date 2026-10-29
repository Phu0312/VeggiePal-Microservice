import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuthStore } from "@/features/auth/store/authStore";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { flattenCategories } from "@/features/blog/utils/feedFilters";
import VideoForm from "@/features/video/components/VideoForm";
import { useVideo } from "@/features/video/hooks/useVideos";

// Popup đăng video mới (không có videoId) và sửa video (có videoId), cần đăng nhập.
// `initialVideo`: video đã có sẵn (mở từ "Nội dung của tôi") để sửa được cả bản nháp / bị từ chối;
// nếu không có thì gọi GET /videos/:id (chỉ video đã đăng).
export default function VideoFormDialog({ videoId, initialVideo, onClose }) {
  const isEdit = videoId !== undefined;
  const id = Number.isInteger(videoId) && videoId > 0 ? videoId : null;

  const user = useAuthStore((s) => s.user);
  const {
    data: categoryTree,
    isPending: categoriesPending,
    isError: categoriesError,
  } = useCategories();

  const shouldFetch = isEdit && !initialVideo && id !== null;
  const {
    data: fetchedVideo,
    isPending: videoPending,
    isError: videoError,
  } = useVideo(shouldFetch ? id : null);

  const video = initialVideo ?? fetchedVideo;
  const canEdit = !isEdit || (video && (video.authorId === user?.id || user?.role === "ADMIN"));

  let body;
  if (isEdit && id === null) {
    body = (
      <Notice title="Video không hợp lệ" onClose={onClose}>
        Video không đúng định dạng.
      </Notice>
    );
  } else if (isEdit && !initialVideo && videoError) {
    body = (
      <Notice title="Không mở được video này để sửa" onClose={onClose}>
        Hiện chỉ mở trực tiếp được video đã đăng, hoặc bạn có thể mở từ mục “Nội dung của tôi”.
      </Notice>
    );
  } else if (isEdit && !videoPending && !canEdit) {
    body = (
      <Notice title="Bạn không có quyền sửa video này" onClose={onClose}>
        Chỉ tác giả hoặc quản trị viên mới sửa được video này.
      </Notice>
    );
  } else if (categoriesError) {
    body = (
      <Notice title="Không tải được danh mục" onClose={onClose}>
        Vui lòng thử lại sau.
      </Notice>
    );
  } else if (categoriesPending || (isEdit && !video && videoPending)) {
    body = <FormSkeleton />;
  } else {
    body = (
      <VideoForm
        video={isEdit ? video : undefined}
        categories={flattenCategories(categoryTree)}
        onClose={onClose}
      />
    );
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-3xl bg-surface">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Chỉnh sửa video" : "Đăng video nấu ăn"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Cập nhật tiêu đề, mô tả và danh mục của video."
              : "Tải tệp .mp4 hoặc dán liên kết YouTube để chia sẻ cách nấu món chay."}
          </DialogDescription>
        </DialogHeader>
        {body}
      </DialogContent>
    </Dialog>
  );
}

function Notice({ title, children, onClose }) {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center">
      <h2 className="font-heading text-xl font-bold text-ink">{title}</h2>
      <p className="mt-2 text-sm text-subtle">{children}</p>
      <Button type="button" className="mt-4" onClick={onClose}>
        Đóng
      </Button>
    </div>
  );
}

function FormSkeleton() {
  return (
    <div aria-hidden className="animate-pulse space-y-5 rounded-3xl border border-border bg-card p-5 sm:p-6">
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="aspect-video w-full rounded-2xl bg-surface" />
      <div className="h-32 w-full rounded-xl bg-surface" />
    </div>
  );
}
