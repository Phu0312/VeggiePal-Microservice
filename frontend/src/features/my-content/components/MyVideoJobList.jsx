import { useState } from "react";
import { Link } from "react-router-dom";
import { FileVideo, Loader2 } from "lucide-react";

import { Button } from "@/components/ui/button";
import { formatTimeAgo } from "@/features/blog/utils/blogFormat";
import StatusBadge from "@/features/my-content/components/StatusBadge";
import { getVideoJobStatusInfo } from "@/features/my-content/utils/statusInfo";
import VideoJobResultDialog from "@/features/video/components/VideoJobResultDialog";
import { useVideoJobs } from "@/features/video/hooks/useVideoJobs";
import { describeJobError, isJobResultExpired, jobSourceLabel } from "@/features/video/utils/videoJob";

// Tab "Bóc tách": lịch sử bóc tách công thức từ video (GET /ai/videos), mới nhất trước, "Xem thêm".
// Job đang xử lý tự cập nhật; BE không có sửa / xóa job nên mỗi dòng chỉ có "Xem kết quả".
export default function MyVideoJobList() {
  const [viewing, setViewing] = useState(null);
  const {
    jobs,
    total,
    isPending,
    isError,
    error,
    hasNextPage,
    fetchNextPage,
    isFetchingNextPage,
  } = useVideoJobs();

  if (isError) {
    return (
      <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
    );
  }
  if (isPending) return <RowSkeletons />;
  if (jobs.length === 0) {
    return (
      <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
        Bạn chưa bóc tách video nào. Bấm “Bóc tách video” để AI lấy công thức từ một video nấu ăn.
      </p>
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-xs text-subtle">{total} lượt bóc tách</p>
      <ul className="flex flex-col gap-3">
        {jobs.map((job) => (
          <JobRow key={job.id} job={job} onView={() => setViewing(job)} />
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
            "Xem thêm"
          )}
        </Button>
      )}

      <VideoJobResultDialog job={viewing} onClose={() => setViewing(null)} />
    </div>
  );
}

function JobRow({ job, onView }) {
  const info = getVideoJobStatusInfo(job.status);
  const expired = isJobResultExpired(job);
  const processing = job.status === "PROCESSING";

  return (
    <li className="rounded-3xl border border-border bg-card p-4 shadow-sm">
      <div className="flex gap-4">
        <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-surface text-subtle">
          {processing ? (
            <Loader2 className="size-6 animate-spin text-brand" />
          ) : (
            <FileVideo className="size-6" />
          )}
        </span>

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <StatusBadge info={info} />
            <span className="text-xs text-subtle">{formatTimeAgo(job.createdAt)}</span>
          </div>
          <h3 className="mt-1.5 line-clamp-2 break-all font-heading text-base font-bold leading-snug text-ink">
            {job.status === "COMPLETED" && job.extraction?.title ? job.extraction.title : jobSourceLabel(job)}
          </h3>
          {job.status === "COMPLETED" && job.extraction?.title && (
            <p className="mt-0.5 truncate text-xs text-subtle">
              {job.sourceVideoId ? (
                <>
                  Từ{" "}
                  <Link to={`/videos/${job.sourceVideoId}`} className="font-medium text-brand hover:underline">
                    {jobSourceLabel(job).toLowerCase()}
                  </Link>
                </>
              ) : (
                <>Từ video “{job.filename}”</>
              )}
            </p>
          )}
          {info.hint && <p className="mt-1 text-xs text-subtle">{info.hint}</p>}
          {job.status === "FAILED" && (
            <p className="mt-1 text-xs text-destructive">{describeJobError(job.error)}</p>
          )}
          {expired && (
            <p className="mt-1 text-xs text-subtle">Kết quả đã hết hạn lưu (hệ thống chỉ giữ 30 ngày).</p>
          )}
        </div>
      </div>

      {job.status === "COMPLETED" && !expired && (
        <div className="mt-3 flex justify-end border-t border-border pt-3">
          <Button type="button" size="xs" onClick={onView}>
            Xem kết quả
          </Button>
        </div>
      )}
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
          <div className="size-14 shrink-0 rounded-2xl bg-surface" />
          <div className="flex-1 space-y-2.5 py-1">
            <div className="h-4 w-20 rounded-full bg-surface" />
            <div className="h-4 w-4/5 rounded bg-surface" />
          </div>
        </div>
      ))}
    </div>
  );
}
