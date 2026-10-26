import { useId, useState } from "react";
import { Link } from "react-router-dom";
import { FileVideo, Loader2, UploadCloud } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { useMySubscription } from "@/features/payment/hooks/useMySubscription";
import { useStartVideoJob } from "@/features/video/hooks/useVideoJobs";
import {
  formatFileSize,
  validateJobFile,
  VIDEO_JOB_MAX_MINUTES,
} from "@/features/video/utils/videoJob";
import { cn } from "@/lib/utils";

/**
 * Hộp thoại chọn tệp video để AI bóc tách công thức (POST /ai/videos/process).
 * Gửi xong BE trả 202 ngay, kết quả hiện dần trong danh sách (tab "Bóc tách") nên hộp thoại đóng luôn.
 * Gói không có lượt bóc tách (videosPerMonth = 0, vd FREE) thì chặn sớm và mời nâng cấp.
 */
export default function UploadVideoJobDialog({ open, onOpenChange }) {
  const inputId = useId();
  const [file, setFile] = useState(null);
  const [fileError, setFileError] = useState("");
  const [serverError, setServerError] = useState("");
  const [progress, setProgress] = useState(0);

  const { subscription } = useMySubscription();
  const startJob = useStartVideoJob();
  const uploading = startJob.isPending;
  // Chưa biết gói (đang tải / lỗi) thì không chặn, để BE quyết định.
  const noQuota = subscription?.videosPerMonth === 0;

  const reset = () => {
    setFile(null);
    setFileError("");
    setServerError("");
    setProgress(0);
  };

  // Đang tải lên thì không cho đóng để khỏi mất tiến trình.
  const handleOpenChange = (next) => {
    if (uploading) return;
    if (!next) reset();
    onOpenChange(next);
  };

  const handleFileChange = (event) => {
    const picked = event.target.files?.[0];
    // Cho phép chọn lại đúng tệp đó sau khi bị báo lỗi.
    event.target.value = "";
    if (!picked) return;

    setServerError("");
    const error = validateJobFile(picked);
    setFileError(error ?? "");
    setFile(error ? null : picked);
  };

  const handleSubmit = () => {
    const error = validateJobFile(file);
    if (error) {
      setFileError(error);
      return;
    }

    setServerError("");
    setProgress(0);
    startJob.mutate(
      {
        file,
        onUploadProgress: (event) => {
          if (event.total) setProgress(Math.round((event.loaded * 100) / event.total));
        },
      },
      {
        onSuccess: () => {
          toast.info("Đã gửi video, AI đang bóc tách công thức. Bạn có thể rời trang này.");
          reset();
          onOpenChange(false);
        },
        onError: (err) => setServerError(err.message),
      },
    );
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Bóc tách công thức từ video</DialogTitle>
          <DialogDescription>
            AI nghe lời trong video rồi liệt kê nguyên liệu và các bước làm. Video cần nói rõ nguyên liệu kèm
            số lượng thì kết quả mới đầy đủ.
          </DialogDescription>
        </DialogHeader>

        {noQuota ? (
          <div className="flex flex-col gap-3 rounded-2xl bg-warning/15 px-4 py-3 text-sm text-warning">
            <p>
              Gói hiện tại của bạn chưa có lượt bóc tách video. Nâng cấp lên gói PLUS hoặc PRO để dùng
              tính năng này.
            </p>
            <Link
              to="/pricing"
              className={buttonVariants({ variant: "default", size: "sm", className: "self-start" })}
            >
              Xem các gói thành viên
            </Link>
          </div>
        ) : (
          <>
            <label
              htmlFor={inputId}
              className={cn(
                "flex cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed p-6 text-center transition",
                uploading && "pointer-events-none opacity-70",
                fileError
                  ? "border-destructive/60 bg-destructive/5"
                  : file
                    ? "border-brand bg-brand-soft/30"
                    : "border-border bg-surface hover:border-brand/40 hover:bg-brand-soft/10",
              )}
            >
              {file ? (
                <FileVideo className="size-8 text-brand" />
              ) : (
                <UploadCloud className="size-8 text-subtle" />
              )}
              <span className="mt-2 max-w-full truncate text-sm font-semibold text-ink">
                {file ? file.name : "Nhấp để chọn tệp video"}
              </span>
              <span className="mt-0.5 text-xs text-subtle">
                {file
                  ? `${formatFileSize(file.size)} / tối đa 100MB`
                  : `Tối đa 100MB, dài tối đa ${VIDEO_JOB_MAX_MINUTES} phút`}
              </span>
              <input
                id={inputId}
                type="file"
                accept="video/*"
                disabled={uploading}
                onChange={handleFileChange}
                className="sr-only"
              />
            </label>
            {fileError && <p className="-mt-2 text-xs text-destructive">{fileError}</p>}

            {uploading && (
              <div className="flex flex-col gap-1.5">
                <div className="flex justify-between text-xs text-subtle">
                  <span>{progress < 100 ? "Đang tải video lên..." : "Đang kiểm tra video..."}</span>
                  <span className="font-semibold text-brand">{progress}%</span>
                </div>
                <div className="h-2 w-full overflow-hidden rounded-full bg-surface">
                  <div
                    className="h-full bg-brand transition-all duration-200"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>
            )}

            {serverError && (
              <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
                {serverError}
              </p>
            )}
          </>
        )}

        <DialogFooter>
          <Button type="button" variant="ghost" disabled={uploading} onClick={() => handleOpenChange(false)}>
            Hủy
          </Button>
          {!noQuota && (
            <Button type="button" disabled={!file || uploading} onClick={handleSubmit}>
              {uploading && <Loader2 className="size-4 animate-spin" />}
              Bóc tách
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
