import { useId, useState } from "react";
import { useNavigate } from "react-router-dom";
import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { Controller, useForm, useWatch } from "react-hook-form";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import ThumbnailPicker from "@/features/blog/components/ThumbnailPicker";
import {
  useCreateBlog,
  useSubmitBlog,
  useUpdateBlog,
  useUploadBlogThumbnail,
} from "@/features/blog/hooks/useBlogMutations";
import { BLOG_CONTENT_MIN, BLOG_TITLE_MAX, blogSchema } from "@/features/blog/schema";
import { describeBlogOutcome } from "@/features/blog/utils/blogForm";
import SelectField from "@/shared/components/SelectField";

const fieldClass =
  "w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";
const labelClass = "mb-1.5 block text-sm font-semibold text-ink";
const errorClass = "mt-1.5 text-xs text-destructive";

const notify = ({ tone, message }) =>
  tone === "error" ? toast.error(message) : tone === "info" ? toast.info(message) : toast.success(message);

/**
 * Form viết / sửa bài.
 * - Tạo mới (không có `blog`): "Lưu nháp" hoặc "Đăng bài" (kiểm duyệt ngay).
 * - Sửa (`blog` là BlogResponse, mọi trạng thái trừ BANNED): "Lưu thay đổi". Bản nháp vẫn là nháp;
 *   bài đã qua kiểm duyệt (đã đăng, chờ duyệt, bị từ chối) sẽ được BE kiểm duyệt lại.
 * `categories` là danh sách phẳng { id, name } của danh mục đang hoạt động.
 * Ảnh bìa tải lên bằng endpoint riêng sau khi bài đã có id.
 */
export default function BlogForm({ blog, categories }) {
  const idPrefix = useId();
  const navigate = useNavigate();
  const isEdit = Boolean(blog);
  const [thumbnailFile, setThumbnailFile] = useState(null);

  const createBlog = useCreateBlog();
  const updateBlog = useUpdateBlog();
  const submitBlog = useSubmitBlog();
  const uploadThumbnail = useUploadBlogThumbnail();

  const {
    register,
    handleSubmit,
    setError,
    control,
    formState: { errors, isSubmitting },
  } = useForm({
    resolver: zodResolver(blogSchema),
    defaultValues: {
      title: blog?.title ?? "",
      categoryId: blog ? String(blog.categoryId) : "",
      content: blog?.content ?? "",
    },
  });

  const titleLength = useWatch({ control, name: "title" }).length;
  const contentLength = useWatch({ control, name: "content" }).trim().length;
  const categoryOptions = categories.map(({ id, name }) => ({ value: String(id), label: name }));

  // Trả true nếu tải ảnh thành công; lỗi thì báo nhưng không chặn, vì bài đã được lưu.
  const uploadThumbnailSafely = async (id) => {
    try {
      await uploadThumbnail.mutateAsync({ id, file: thumbnailFile });
      return true;
    } catch (error) {
      toast.error(`Bài đã được lưu nhưng tải ảnh bìa thất bại: ${error.message}`);
      return false;
    }
  };

  const finish = (result, message) => {
    notify(message ?? describeBlogOutcome(result));
    navigate(result.status === "PUBLISHED" ? `/blog/${result.id}` : "/my-content");
  };

  const save = (publish) =>
    handleSubmit(async (values) => {
      const payload = {
        title: values.title,
        content: values.content,
        categoryId: Number(values.categoryId),
      };

      try {
        if (isEdit) {
          const updated = await updateBlog.mutateAsync({ id: blog.id, ...payload });
          if (thumbnailFile) await uploadThumbnailSafely(blog.id);
          finish(
            updated,
            updated.status === "PUBLISHED"
              ? { tone: "success", message: "Đã cập nhật bài viết" }
              : undefined
          );
          return;
        }

        // Đăng kèm ảnh: tạo nháp -> tải ảnh -> gửi duyệt, để bài vừa đăng đã có ảnh bìa.
        if (publish && thumbnailFile) {
          const draft = await createBlog.mutateAsync({ ...payload, publish: false });
          if (!(await uploadThumbnailSafely(draft.id))) {
            toast.info("Bài được lưu dưới dạng bản nháp, bạn có thể gửi duyệt lại sau.");
            navigate("/my-content");
            return;
          }
          finish(await submitBlog.mutateAsync(draft.id));
          return;
        }

        const created = await createBlog.mutateAsync({ ...payload, publish });
        if (thumbnailFile) await uploadThumbnailSafely(created.id);
        finish(created);
      } catch (error) {
        setError("root", { message: error.message });
      }
    });

  return (
    <form onSubmit={(event) => event.preventDefault()} noValidate className="flex flex-col gap-5">
      <section className="flex flex-col gap-5 rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
        {isEdit && blog.status === "DRAFT" ? (
          <p className="rounded-xl bg-brand-soft px-3 py-2 text-sm text-brand">
            Đây là bản nháp, chỉ mình bạn thấy. Sửa xong bạn bấm “Gửi duyệt” ở trang Bài viết của tôi để đăng.
          </p>
        ) : isEdit ? (
          <p className="rounded-xl bg-warning/10 px-3 py-2 text-sm text-warning">
            {blog.status === "PUBLISHED"
              ? "Bài đã đăng sẽ được kiểm duyệt lại sau khi sửa và có thể bị ẩn tạm thời cho tới khi được duyệt."
              : "Bài sẽ được kiểm duyệt lại ngay khi bạn lưu thay đổi."}
          </p>
        ) : (
          <p className="rounded-xl bg-brand-soft px-3 py-2 text-sm text-brand">
            “Lưu nháp” chỉ lưu cho riêng bạn. “Đăng bài” sẽ gửi đi kiểm duyệt ngay.
          </p>
        )}

        <div>
          <label htmlFor={`${idPrefix}-title`} className={labelClass}>
            Tiêu đề
          </label>
          <input
            id={`${idPrefix}-title`}
            type="text"
            placeholder="Ví dụ: Súp bí đỏ hạt sen giữ ấm ngày se lạnh"
            aria-invalid={Boolean(errors.title)}
            className={`${fieldClass} h-11`}
            {...register("title")}
          />
          <div className="mt-1.5 flex justify-between gap-2">
            <p className={errors.title ? "text-xs text-destructive" : "text-xs text-transparent"}>
              {errors.title?.message ?? "."}
            </p>
            <span className="text-xs text-subtle">
              {titleLength}/{BLOG_TITLE_MAX}
            </span>
          </div>
        </div>

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

        <div>
          <span className={labelClass}>Ảnh bìa (không bắt buộc)</span>
          <ThumbnailPicker currentUrl={blog?.thumbnailUrl} onChange={setThumbnailFile} />
        </div>

        <div>
          <label htmlFor={`${idPrefix}-content`} className={labelClass}>
            Nội dung
          </label>
          <textarea
            id={`${idPrefix}-content`}
            rows={14}
            placeholder="Chia sẻ công thức, kinh nghiệm hoặc kiến thức dinh dưỡng của bạn..."
            aria-invalid={Boolean(errors.content)}
            className={`${fieldClass} resize-y py-3 leading-relaxed`}
            {...register("content")}
          />
          <div className="mt-1.5 flex justify-between gap-2">
            <p className={errors.content ? "text-xs text-destructive" : "text-xs text-transparent"}>
              {errors.content?.message ?? "."}
            </p>
            <span className="text-xs text-subtle">
              {contentLength} ký tự (tối thiểu {BLOG_CONTENT_MIN})
            </span>
          </div>
        </div>

        {errors.root && (
          <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {errors.root.message}
          </p>
        )}
      </section>

      <div className="flex flex-wrap justify-end gap-2">
        <Button type="button" variant="ghost" disabled={isSubmitting} onClick={() => navigate(-1)}>
          Hủy
        </Button>
        {isEdit ? (
          <Button type="button" disabled={isSubmitting} onClick={save(false)}>
            {isSubmitting && <Loader2 className="size-4 animate-spin" />}
            Lưu thay đổi
          </Button>
        ) : (
          <>
            <Button type="button" variant="outline" disabled={isSubmitting} onClick={save(false)}>
              Lưu nháp
            </Button>
            <Button type="button" disabled={isSubmitting} onClick={save(true)}>
              {isSubmitting && <Loader2 className="size-4 animate-spin" />}
              Đăng bài
            </Button>
          </>
        )}
      </div>
    </form>
  );
}
