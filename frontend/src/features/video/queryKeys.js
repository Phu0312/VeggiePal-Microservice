// Khóa cache React Query của feature video.
export const videoKeys = {
  all: ["videos"],
  feed: ({ categoryId, size } = {}) => [
    "videos",
    "feed",
    { categoryId: categoryId || undefined, size },
  ],
  detail: (id) => ["videos", "detail", id],
  mine: (status, size) => ["videos", "mine", { status: status || undefined, size }],
  // Job bóc tách công thức (ai-service); tách khỏi `all` để đăng video không làm tải lại danh sách job.
  jobsRoot: ["video-jobs"],
  jobsList: ["video-jobs", "list"],
  jobs: (size) => ["video-jobs", "list", { size }],
  // Công thức AI dùng chung của một video đã đăng (GET /ai/videos/by-video/:id).
  recipe: (videoId) => ["video-jobs", "recipe", videoId],
  // Khóa của mutation gửi bóc tách, để nút và thẻ AI cùng biết đang gửi (useIsMutating).
  recipeRun: (videoId) => ["video-jobs", "recipe-run", videoId],
};
