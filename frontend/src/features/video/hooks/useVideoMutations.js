import { useMutation, useQueryClient } from "@tanstack/react-query";

import {
  createVideo,
  deleteVideo,
  submitVideo,
  updateVideo,
} from "@/features/video/api/videoApi";
import { videoKeys } from "@/features/video/queryKeys";

function useInvalidateVideos() {
  const queryClient = useQueryClient();
  return () => queryClient.invalidateQueries({ queryKey: videoKeys.all });
}

/**
 * Đăng video mới (multipart).
 * mutate({ formData, onUploadProgress }) -> VideoResponse.
 */
export function useCreateVideo() {
  const invalidate = useInvalidateVideos();
  return useMutation({
    mutationFn: ({ formData, onUploadProgress }) =>
      createVideo(formData, { onUploadProgress }),
    onSuccess: invalidate,
  });
}

/**
 * Cập nhật tiêu đề, mô tả, danh mục video.
 * mutate({ id, title, description, categoryId }) -> VideoResponse.
 */
export function useUpdateVideo() {
  const invalidate = useInvalidateVideos();
  return useMutation({
    mutationFn: ({ id, ...payload }) => updateVideo(id, payload),
    onSuccess: invalidate,
  });
}

/**
 * Gửi bản nháp đi kiểm duyệt.
 * mutate(id) -> VideoResponse.
 */
export function useSubmitVideo() {
  const invalidate = useInvalidateVideos();
  return useMutation({
    mutationFn: submitVideo,
    onSuccess: invalidate,
  });
}

/**
 * Xóa video.
 * mutate(id).
 */
export function useDeleteVideo() {
  const invalidate = useInvalidateVideos();
  return useMutation({
    mutationFn: deleteVideo,
    onSuccess: invalidate,
  });
}
