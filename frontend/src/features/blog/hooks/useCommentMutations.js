import { useMutation, useQueryClient } from "@tanstack/react-query";

import { createComment, deleteComment, updateComment } from "@/features/blog/api/commentApi";
import { blogKeys } from "@/features/blog/queryKeys";

// Thêm / sửa / xóa comment đều làm mới toàn bộ cache comment (danh sách gốc lẫn reply),
// vì replyCount của comment gốc và thứ tự hiển thị phụ thuộc vào dữ liệu server.
// Không ghi tay vào cache: comment mới đi qua kiểm duyệt nên có thể không hiện ra.
function useInvalidateComments() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: blogKeys.comments });
}

/** Gửi bình luận mới hoặc phản hồi. mutate({ blogId, parentCommentId?, content }). */
export function useCreateComment() {
  const invalidate = useInvalidateComments();
  return useMutation({ mutationFn: createComment, onSuccess: invalidate });
}

/** Sửa bình luận của mình. mutate({ commentId, blogId, content }). */
export function useUpdateComment() {
  const invalidate = useInvalidateComments();
  return useMutation({
    mutationFn: ({ commentId, blogId, content }) =>
      updateComment(commentId, { blogId, content }),
    onSuccess: invalidate,
  });
}

/** Xóa bình luận (chủ comment hoặc ADMIN). mutate(commentId). */
export function useDeleteComment() {
  const invalidate = useInvalidateComments();
  return useMutation({ mutationFn: deleteComment, onSuccess: invalidate });
}
