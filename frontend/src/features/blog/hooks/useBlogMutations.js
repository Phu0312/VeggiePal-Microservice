import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  createBlog,
  deleteBlog,
  submitBlog,
  updateBlog,
  uploadBlogThumbnail,
} from "@/features/blog/api/blogApi";
import { blogKeys } from "@/features/blog/queryKeys";

// Mọi thay đổi bài viết đều làm mới cache "blog/posts" (feed, chi tiết, bài của tôi, bài liên quan),
// vì trạng thái bài phụ thuộc kết quả kiểm duyệt của server nên không ghi tay vào cache.
function useInvalidateBlogs() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: blogKeys.blogs });
}

/** Tạo bài. mutate({ title, content, categoryId, publish }) -> BlogResponse. */
export function useCreateBlog() {
  const invalidate = useInvalidateBlogs();
  return useMutation({ mutationFn: createBlog, onSuccess: invalidate });
}

/** Sửa bài. mutate({ id, title, content, categoryId }) -> BlogResponse (có thể bị kiểm duyệt lại). */
export function useUpdateBlog() {
  const invalidate = useInvalidateBlogs();
  return useMutation({
    mutationFn: ({ id, ...payload }) => updateBlog(id, payload),
    onSuccess: invalidate,
  });
}

/** Gửi bản nháp đi kiểm duyệt. mutate(id) -> BlogResponse. */
export function useSubmitBlog() {
  const invalidate = useInvalidateBlogs();
  return useMutation({ mutationFn: submitBlog, onSuccess: invalidate });
}

/** Xóa bài. mutate(id). */
export function useDeleteBlog() {
  const invalidate = useInvalidateBlogs();
  return useMutation({ mutationFn: deleteBlog, onSuccess: invalidate });
}

/** Tải ảnh bìa. mutate({ id, file }) -> BlogResponse có thumbnailUrl mới. */
export function useUploadBlogThumbnail() {
  const invalidate = useInvalidateBlogs();
  return useMutation({
    mutationFn: ({ id, file }) => uploadBlogThumbnail(id, file),
    onSuccess: invalidate,
  });
}
