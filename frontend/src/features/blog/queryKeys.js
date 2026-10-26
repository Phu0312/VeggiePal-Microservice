// Khóa cache React Query của feature blog (danh mục, bài viết, bình luận).
// Khóa phân cấp: invalidateQueries({ queryKey: blogKeys.blogs }) làm mới cả feed lẫn chi tiết.
export const blogKeys = {
  categories: ["blog", "categories"],
  categoryTree: (type, activeOnly) => [
    "blog",
    "categories",
    "tree",
    { type, activeOnly },
  ],
  category: (id) => ["blog", "categories", "detail", id],

  blogs: ["blog", "posts"],
  feeds: ["blog", "posts", "feed"],
  feed: (params) => ["blog", "posts", "feed", params],
  detail: (id) => ["blog", "posts", "detail", id],
  related: (id) => ["blog", "posts", "related", id],
  mine: (status, size) => ["blog", "posts", "mine", { status, size }],

  // Vote của tôi trên danh sách bài (chỉ có khi đăng nhập).
  myVotes: ["blog", "my-votes"],
  myVoteList: (ids) => ["blog", "my-votes", ids],

  comments: ["blog", "comments"],
  commentList: (targetId, params) => ["blog", "comments", "list", targetId, params],
  replies: (commentId, params) => ["blog", "comments", "replies", commentId, params],
};
