import { useState } from "react";
import { Link } from "react-router-dom";
import { Eye, Loader2, PlaySquare } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { formatCompactNumber, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import StatusBadge from "@/features/my-content/components/StatusBadge";
import {
  canEditVideo,
  canSubmitVideo,
  getVideoStatusInfo,
  VIDEO_STATUS_FILTERS,
} from "@/features/my-content/utils/statusInfo";
import { useDeleteVideo, useSubmitVideo } from "@/features/video/hooks/useVideoMutations";
import { useMyVideos } from "@/features/video/hooks/useMyVideos";
import { describeVideoOutcome } from "@/features/video/utils/videoForm";
import { cn } from "@/lib/utils";
import ConfirmDialog from "@/shared/components/ConfirmDialog";
import FallbackImage from "@/shared/components/FallbackImage";

// Tab "Video": lọc theo trạng thái (GET /videos/me?status=) + danh sách "Xem thêm",
// mỗi dòng có Sửa / Gửi duyệt / Xóa tùy trạng thái.
export default function MyVideoList() {
  const [status, setStatus] = useState("");
  const {
    videos,
    total,
    isPending,
    isError,
    error,
    hasNextPage,
    fetchNextPage,
    isFetchingNextPage,
  } = useMyVideos({ status });

  return (
    <div className="flex flex-col gap-4">
      <div className="no-scrollbar flex items-center gap-1 overflow-x-auto">
        {VIDEO_STATUS_FILTERS.map(({ value, label }) => (
          <button
            key={label}
            type="button"
            onClick={() => setStatus(value)}
            aria-pressed={status === value}
            className={cn(
              "shrink-0 rounded-full px-3.5 py-1.5 text-sm font-medium transition",
              status === value
                ? "bg-brand-soft text-brand"
                : "text-subtle hover:bg-surface hover:text-ink"
            )}
          >
            {label}
          </button>
        ))}
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {error.message}
        </p>
      ) : isPending ? (
        <RowSkeletons />
      ) : videos.length === 0 ? (
        <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
          {status ? "Không có video nào ở trạng thái này." : "Bạn chưa đăng video nào."}
        </p>
      ) : (
        <>
          <p className="text-xs text-subtle">{total} video</p>
          <ul className="flex flex-col gap-3">
            {videos.map((video) => (
              <VideoRow key={video.id} video={video} />
            ))}
          </ul>
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
                "Xem thêm video"
              )}
            </Button>
          )}
        </>
      )}
    </div>
  );
}

function VideoRow({ video }) {
  const [confirmDelete, setConfirmDelete] = useState(false);
  const submitVideo = useSubmitVideo();
  const deleteVideo = useDeleteVideo();

  const info = getVideoStatusInfo(video.status);
  const isPublished = video.status === "PUBLISHED";

  const handleSubmit = () =>
    submitVideo.mutate(video.id, {
      onSuccess: (result) => {
        const { tone, message } = describeVideoOutcome(result);
        if (tone === "error") toast.error(message);
        else if (tone === "info") toast.info(message);
        else toast.success(message);
      },
      onError: (error) => toast.error(error.message),
    });

  const handleDelete = () =>
    deleteVideo.mutate(video.id, {
      onSuccess: () => {
        setConfirmDelete(false);
        toast.success("Đã xóa video");
      },
      onError: (error) => toast.error(error.message),
    });

  const summary = (
    <>
      <div className="relative size-20 shrink-0 overflow-hidden rounded-2xl bg-surface">
        <FallbackImage
          src={video.thumbnailUrl}
          alt={video.title}
          className="size-full object-cover"
          draggable={false}
          fallback={
            <span className="grid size-full place-items-center bg-surface text-subtle">
              <PlaySquare className="size-6 text-subtle" />
            </span>
          }
        />
        <span className="absolute bottom-1 right-1 rounded bg-black/70 px-1 py-0.5 text-[10px] font-medium text-white">
          {video.sourceType === "YOUTUBE" ? "YouTube" : "MP4"}
        </span>
      </div>

      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <StatusBadge info={info} />
          {video.categoryName && (
            <span className="text-xs text-subtle">{video.categoryName}</span>
          )}
        </div>
        <h3 className="mt-1.5 line-clamp-2 font-heading text-base font-bold leading-snug text-ink">
          {video.title}
        </h3>
        <p className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-subtle">
          <span>{formatTimeAgo(video.publishedAt ?? video.createdAt)}</span>
          {isPublished ? (
            <span className="flex items-center gap-1">
              <Eye className="size-3.5" />
              {formatCompactNumber(video.viewCount)} lượt xem
            </span>
          ) : (
            info.hint && <span>{info.hint}</span>
          )}
        </p>

        {video.status === "REJECTED" && video.moderationReason && (
          <p className="mt-1 text-xs text-destructive">
            Lý do từ chối: {video.moderationReason}
          </p>
        )}
      </div>
    </>
  );

  return (
    <li className="rounded-3xl border border-border bg-card p-4 shadow-sm">
      {isPublished ? (
        <Link to={`/videos/${video.id}`} className="flex gap-4">
          {summary}
        </Link>
      ) : (
        <div className="flex gap-4">{summary}</div>
      )}

      <div className="mt-3 flex flex-wrap justify-end gap-2 border-t border-border pt-3">
        {canEditVideo(video.status) && (
          <Link
            to={`/videos/${video.id}/edit`}
            state={{ video }}
            className={buttonVariants({ variant: "outline", size: "xs" })}
          >
            Sửa
          </Link>
        )}
        {canSubmitVideo(video.status) && (
          <Button
            type="button"
            size="xs"
            disabled={submitVideo.isPending}
            onClick={handleSubmit}
          >
            {submitVideo.isPending && <Loader2 className="size-3 animate-spin" />}
            Gửi duyệt
          </Button>
        )}
        <Button
          type="button"
          size="xs"
          variant="ghost"
          onClick={() => setConfirmDelete(true)}
        >
          <span className="text-destructive">Xóa</span>
        </Button>
      </div>

      <ConfirmDialog
        open={confirmDelete}
        onOpenChange={setConfirmDelete}
        title="Xóa video?"
        description={`“${video.title}” sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác.`}
        loading={deleteVideo.isPending}
        onConfirm={handleDelete}
      />
    </li>
  );
}

function RowSkeletons() {
  return (
    <div aria-hidden className="flex flex-col gap-3">
      {[0, 1, 2].map((i) => (
        <div
          key={i}
          className="flex animate-pulse gap-4 rounded-3xl border border-border bg-card p-4 shadow-sm"
        >
          <div className="size-20 shrink-0 rounded-2xl bg-surface" />
          <div className="flex-1 space-y-2.5 py-1">
            <div className="h-4 w-20 rounded-full bg-surface" />
            <div className="h-4 w-4/5 rounded bg-surface" />
            <div className="h-3 w-1/3 rounded bg-surface" />
          </div>
        </div>
      ))}
    </div>
  );
}
