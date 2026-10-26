// Cập nhật cache React Query sau khi vote, để không phải tải lại cả feed.
// `vote` là VoteResponse của BE: { blogId, myVote: 1 | -1 | null, voteScore }.

/** Cache "vote của tôi" (mảng { blogId, myVote }): ghi đè phần tử của blog đó, thêm nếu chưa có. */
export function applyVoteToMyVotes(list, vote) {
  if (!list) return list;
  const exists = list.some((v) => v.blogId === vote.blogId);
  if (!exists) return [...list, { blogId: vote.blogId, myVote: vote.myVote }];
  return list.map((v) => (v.blogId === vote.blogId ? { ...v, myVote: vote.myVote } : v));
}

/** Cache feed dạng useInfiniteQuery ({ pages: [{ items }] }): cập nhật voteScore của bài đó. */
export function applyVoteToFeed(data, vote) {
  if (!data?.pages) return data;
  return {
    ...data,
    pages: data.pages.map((page) => ({
      ...page,
      items: (page.items ?? []).map((blog) =>
        blog.id === vote.blogId ? { ...blog, voteScore: vote.voteScore } : blog
      ),
    })),
  };
}

/** Cache chi tiết một bài: cập nhật voteScore. */
export function applyVoteToBlog(blog, vote) {
  if (!blog) return blog;
  return { ...blog, voteScore: vote.voteScore };
}
