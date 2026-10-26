import { useEffect, useId, useState } from "react";
import { useNavigate } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { FileVideo, Loader2, SquarePlay, UploadCloud } from "lucide-react";
import { Controller, useForm, useWatch } from "react-hook-form";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import {
  useCreateVideo,
  useUpdateVideo,
} from "@/features/video/hooks/useVideoMutations";
import { videoCreateSchema, videoEditSchema } from "@/features/video/schema";
import {
  describeVideoOutcome,
  extractYouTubeId,
  validateVideoFile,
  VIDEO_DESCRIPTION_MAX,
  VIDEO_TITLE_MAX,
} from "@/features/video/utils/videoForm";
import { cn } from "@/lib/utils";
import SelectField from "@/shared/components/SelectField";

const fieldClass =
  "w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";
const errorClass = "mt-1.5 text-xs text-destructive";

/**
 * Form đăng / sửa video.
 * - Đăng mới: hỗ trợ tệp .mp4 (≤ 30MB) có thanh tiến trình upload, hoặc liên kết YouTube.
 *   Lựa chọn "Lưu nháp" hoặc "Đăng video" (gửi kiểm duyệt ngay).
 * - Sửa: cập nhật tiêu đề, danh mục, mô tả (nguồn video giữ nguyên theo luật BE).
 */
export default function VideoForm({ video, categories = [] }) {
  const idPrefix = useId();
  const navigate = useNavigate();
  const isEdit = Boolean(video);

  const [videoFile, setVideoFile] = useState(null);
  const [fileError, setFileError] = useState("");
  const [filePreviewUrl, setFilePreviewUrl] = useState(null);
  const [uploadProgress, setUploadProgress] = useState(0);

  const createVideo = useCreateVideo();
  const updateVideo = useUpdateVideo();

  const {
    register,
    handleSubmit,
    setValue,
    setError,
    control,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(isEdit ? videoEditSchema : videoCreateSchema),
    defaultValues: {
      title: video?.title ?? "",
      categoryId: video ? String(video.categoryId) : "",
      description: video?.description ?? "",
      sourceType: video?.sourceType ?? "UPLOAD",
      youtubeUrl: video?.sourceType === "YOUTUBE" ? video.videoUrl : "",
    },
  });

  const sourceType = useWatch({ control, name: "sourceType" });
  const youtubeUrl = useWatch({ control, name: "youtubeUrl" });
  const titleLength = useWatch({ control, name: "title" })?.length ?? 0;
  const descriptionLength = useWatch({ control, name: "description" })?.length ?? 0;
  const categoryOptions = categories.map(({ id, name }) => ({ value: String(id), label: name }));

  const youtubeId = extractYouTubeId(youtubeUrl);

  // Dọn dẹp object URL khi unmount hoặc đổi file
  useEffect(() => {
    return () => {
      if (filePreviewUrl) URL.revokeObjectURL(filePreviewUrl);
    };
  }, [filePreviewUrl]);

  const handleFileChange = (event) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const validationMsg = validateVideoFile(file);
    if (validationMsg) {
      setFileError(validationMsg);
      setVideoFile(null);
      if (filePreviewUrl) URL.revokeObjectURL(filePreviewUrl);
      setFilePreviewUrl(null);
      return;
    }

    setFileError("");
    setVideoFile(file);
    if (filePreviewUrl) URL.revokeObjectURL(filePreviewUrl);
    setFilePreviewUrl(URL.createObjectURL(file));
  };

  const notify = ({ tone, message }) => {
    if (tone === "error") toast.error(message);
    else if (tone === "info") toast.info(message);
    else toast.success(message);
  };

  const finish = (result, customMessage) => {
    notify(customMessage ?? describeVideoOutcome(result));
    if (result.status === "PUBLISHED") {
      navigate(`/videos/${result.id}`);
    } else {
      navigate("/my-content?tab=videos");
    }
  };

  const save = (publish) =>
    handleSubmit(async (values) => {
      try {
        if (isEdit) {
          const updated = await updateVideo.mutateAsync({
            id: video.id,
            title: values.title.trim(),
            description: values.description?.trim() || "",
            categoryId: Number(values.categoryId),
          });

          finish(
            updated,
            updated.status === "PUBLISHED"
              ? { tone: "success", message: "Đã cập nhật video" }
              : undefined
          );
          return;
        }

        // Tạo video mới: chuẩn bị FormData multipart
        if (values.sourceType === "UPLOAD") {
          const err = validateVideoFile(videoFile);
          if (err) {
            setFileError(err);
            return;
          }
        }

        const formData = new FormData();
        formData.append("title", values.title.trim());
        formData.append("categoryId", values.categoryId);
        if (values.description?.trim()) {
          formData.append("description", values.description.trim());
        }
        formData.append("publish", publish ? "true" : "false");

        if (values.sourceType === "UPLOAD" && videoFile) {
          formData.append("file", videoFile);
        } else if (values.sourceType === "YOUTUBE") {
          formData.append("youtubeUrl", values.youtubeUrl.trim());
        }

        setUploadProgress(0);
        const created = await createVideo.mutateAsync({
          formData,
          onUploadProgress: (progressEvent) => {
            if (progressEvent.total) {
              const percent = Math.round(
                (progressEvent.loaded * 100) / progressEvent.total
              );
              setUploadProgress(percent);
            }
          },
        });

        finish(created);
      } catch (err) {
        setError("root", { message: err.message });
      }
    });

  return (
    <form
      onSubmit={(e) => e.preventDefault()}
      noValidate
      className="flex flex-col gap-6"
    >
      <section className="flex flex-col gap-5 rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
        {isEdit ? (
          <p className="rounded-xl bg-warning/15 px-3 py-2 text-sm text-warning">
            Video đã qua duyệt sẽ được kiểm duyệt lại sau khi sửa và có thể bị ẩn tạm thời cho tới khi được duyệt.
          </p>
        ) : (
          <p className="rounded-xl bg-brand-soft px-3 py-2 text-sm text-brand">
            “Lưu nháp” chỉ lưu cho riêng bạn. “Đăng video” sẽ gửi đi kiểm duyệt ngay.
          </p>
        )}

        {/* Nguồn Video: tạo mới thì chọn UPLOAD / YOUTUBE, sửa thì chỉ xem */}
        {!isEdit ? (
          <div>
            <span className={labelClass}>Nguồn video</span>
            <div className="grid grid-cols-2 gap-3 sm:max-w-md">
              <button
                type="button"
                onClick={() => setValue("sourceType", "UPLOAD")}
                className={cn(
                  "flex items-center justify-center gap-2 rounded-2xl border p-3 text-sm font-semibold transition",
                  sourceType === "UPLOAD"
                    ? "border-brand bg-brand-soft text-brand ring-2 ring-brand/20"
                    : "border-border bg-surface text-subtle hover:text-ink"
                )}
              >
                <FileVideo className="size-4" />
                Tải tệp lên (.mp4)
              </button>
              <button
                type="button"
                onClick={() => setValue("sourceType", "YOUTUBE")}
                className={cn(
                  "flex items-center justify-center gap-2 rounded-2xl border p-3 text-sm font-semibold transition",
                  sourceType === "YOUTUBE"
                    ? "border-brand bg-brand-soft text-brand ring-2 ring-brand/20"
                    : "border-border bg-surface text-subtle hover:text-ink"
                )}
              >
                <SquarePlay className="size-4" />
                Liên kết YouTube
              </button>
            </div>

            {sourceType === "UPLOAD" ? (
              <div className="mt-3.5">
                <label
                  htmlFor={`${idPrefix}-file`}
                  className={cn(
                    "flex flex-col items-center justify-center rounded-2xl border-2 border-dashed p-6 text-center transition cursor-pointer",
                    fileError
                      ? "border-destructive/60 bg-destructive/5"
                      : videoFile
                        ? "border-brand bg-brand-soft/30"
                        : "border-border bg-surface hover:border-brand/40 hover:bg-brand-soft/10"
                  )}
                >
                  <UploadCloud className="size-8 text-subtle" />
                  <span className="mt-2 text-sm font-semibold text-ink">
                    {videoFile ? videoFile.name : "Nhấp để chọn tệp video .mp4"}
                  </span>
                  <span className="mt-0.5 text-xs text-subtle">
                    {videoFile
                      ? `${(videoFile.size / (1024 * 1024)).toFixed(1)} MB / tối đa 30MB`
                      : "Định dạng MP4, dung lượng tối đa 30MB"}
                  </span>
                  <input
                    id={`${idPrefix}-file`}
                    type="file"
                    accept="video/mp4"
                    onChange={handleFileChange}
                    className="sr-only"
                  />
                </label>
                {fileError && <p className={errorClass}>{fileError}</p>}

                {filePreviewUrl && (
                  <div className="mt-3 aspect-video w-full max-w-md overflow-hidden rounded-2xl bg-black">
                    <video
                      src={filePreviewUrl}
                      controls
                      className="size-full object-contain"
                    />
                  </div>
                )}
              </div>
            ) : (
              <div className="mt-3.5">
                <label htmlFor={`${idPrefix}-youtube`} className={labelClass}>
                  Đường dẫn video YouTube
                </label>
                <input
                  id={`${idPrefix}-youtube`}
                  type="url"
                  placeholder="Ví dụ: https://www.youtube.com/watch?v=dQw4w9WgXcQ"
                  aria-invalid={Boolean(errors.youtubeUrl)}
                  className={`${fieldClass} h-11`}
                  {...register("youtubeUrl")}
                />
                {errors.youtubeUrl && (
                  <p className={errorClass}>{errors.youtubeUrl.message}</p>
                )}

                {youtubeId && (
                  <div className="mt-3 flex items-center gap-3 rounded-2xl border border-border bg-surface p-3">
                    <img
                      src={`https://img.youtube.com/vi/${youtubeId}/mqdefault.jpg`}
                      alt="Thumbnail YouTube"
                      className="h-16 w-24 shrink-0 rounded-xl object-cover"
                    />
                    <div className="min-w-0 text-xs text-subtle">
                      <p className="font-semibold text-ink">ID: {youtubeId}</p>
                      <p className="mt-0.5 truncate">
                        Sẽ được nhúng trực tiếp qua trình phát YouTube.
                      </p>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        ) : (
          <div className="rounded-2xl border border-border bg-surface p-4">
            <span className="text-xs font-semibold text-subtle uppercase tracking-wide">
              Nguồn phát hiện tại ({video.sourceType === "YOUTUBE" ? "YouTube" : "Tải lên"})
            </span>
            <p className="mt-1 text-sm text-ink truncate">{video.videoUrl}</p>
            <p className="mt-1 text-xs text-subtle">
              Không thể thay đổi nguồn video khi chỉnh sửa. Để đổi nguồn, hãy xóa và đăng lại.
            </p>
          </div>
        )}

        {/* Tiêu đề video */}
        <div>
          <label htmlFor={`${idPrefix}-title`} className={labelClass}>
            Tiêu đề video
          </label>
          <input
            id={`${idPrefix}-title`}
            type="text"
            placeholder="Ví dụ: Cách làm canh chua nấm chay đậm đà chuẩn vị"
            aria-invalid={Boolean(errors.title)}
            className={`${fieldClass} h-11`}
            {...register("title")}
          />
          <div className="mt-1.5 flex justify-between gap-2">
            <p className={errors.title ? errorClass : "text-xs text-transparent"}>
              {errors.title?.message ?? "."}
            </p>
            <span className="text-xs text-subtle">
              {titleLength}/{VIDEO_TITLE_MAX}
            </span>
          </div>
        </div>

        {/* Danh mục */}
        <div>
          <label htmlFor={`${idPrefix}-category`} className={labelClass}>
            Danh mục
          </label>
          <Controller
            name="categoryId"
            control={control}
            render={({ field }) => (
              <SelectField
                id={`${idPrefix}-category`}
                variant="field"
                placeholder="Chọn danh mục"
                options={categoryOptions}
                value={field.value}
                onValueChange={field.onChange}
                onBlur={field.onBlur}
                aria-invalid={Boolean(errors.categoryId)}
              />
            )}
          />
          {errors.categoryId && <p className={errorClass}>{errors.categoryId.message}</p>}
        </div>

        {/* Mô tả */}
        <div>
          <label htmlFor={`${idPrefix}-desc`} className={labelClass}>
            Mô tả video (không bắt buộc)
          </label>
          <textarea
            id={`${idPrefix}-desc`}
            rows={4}
            placeholder="Chia sẻ nguyên liệu, bí quyết nấu ăn hoặc thông tin hữu ích về món ăn..."
            aria-invalid={Boolean(errors.description)}
            className={`${fieldClass} py-2.5`}
            {...register("description")}
          />
          <div className="mt-1.5 flex justify-between gap-2">
            <p className={errors.description ? errorClass : "text-xs text-transparent"}>
              {errors.description?.message ?? "."}
            </p>
            <span className="text-xs text-subtle">
              {descriptionLength}/{VIDEO_DESCRIPTION_MAX}
            </span>
          </div>
        </div>

        {/* Thanh tiến trình upload */}
        {isSubmitting && uploadProgress > 0 && uploadProgress < 100 && (
          <div className="flex flex-col gap-1.5">
            <div className="flex justify-between text-xs text-subtle">
              <span>Đang tải tệp video lên máy chủ...</span>
              <span className="font-semibold text-brand">{uploadProgress}%</span>
            </div>
            <div className="h-2 w-full overflow-hidden rounded-full bg-surface">
              <div
                className="h-full bg-brand transition-all duration-200"
                style={{ width: `${uploadProgress}%` }}
              />
            </div>
          </div>
        )}

        {errors.root && (
          <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {errors.root.message}
          </p>
        )}

        {/* Nút hành động */}
        <div className="flex flex-wrap items-center justify-end gap-3 pt-2">
          <Button
            type="button"
            variant="ghost"
            disabled={isSubmitting}
            onClick={() => navigate("/my-content?tab=videos")}
          >
            Hủy
          </Button>

          {isEdit ? (
            <Button
              type="button"
              disabled={isSubmitting}
              onClick={save(false)}
            >
              {isSubmitting && <Loader2 className="size-4 animate-spin" />}
              Lưu thay đổi
            </Button>
          ) : (
            <>
              <Button
                type="button"
                variant="outline"
                disabled={isSubmitting}
                onClick={save(false)}
              >
                {isSubmitting && <Loader2 className="size-4 animate-spin" />}
                Lưu nháp
              </Button>
              <Button
                type="button"
                disabled={isSubmitting}
                onClick={save(true)}
              >
                {isSubmitting && <Loader2 className="size-4 animate-spin" />}
                Đăng video
              </Button>
            </>
          )}
        </div>
      </section>
    </form>
  );
}
