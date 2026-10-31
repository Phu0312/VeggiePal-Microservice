import { Loader2 } from "lucide-react";

import AuthorAvatar from "@/features/blog/components/AuthorAvatar";
import { FALLBACK_AUTHOR_NAME } from "@/features/blog/utils/blogFormat";
import FollowButton from "@/features/community/components/FollowButton";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

/**
 * Danh sách tác giả có hạng (bảng vàng / kênh video). Tên + avatar lấy qua GET /users/batch.
 * `describe(entry)` trả dòng số liệu dưới tên.
 */
export default function AuthorRankList({ query, describe, emptyText }) {
  const entries = query.data ?? [];
  const { data: authors } = usePublicUsers(entries.map((entry) => entry.authorId));

  if (query.isPending) {
    return (
      <p className="flex items-center gap-2 text-sm text-subtle">
        <Loader2 className="size-4 animate-spin" />
        Đang tải...
      </p>
    );
  }
  if (query.isError) {
    return <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{query.error.message}</p>;
  }
  if (entries.length === 0) {
    return <p className="rounded-2xl bg-surface px-4 py-6 text-center text-sm text-subtle">{emptyText}</p>;
  }

  return (
    <ol className="flex flex-col gap-2">
      {entries.map((entry, index) => {
        const author = authors?.get(entry.authorId);
        return (
          <li key={entry.authorId} className="flex items-center gap-3 rounded-2xl bg-surface p-2.5">
            <span className="w-5 shrink-0 text-center font-heading text-sm font-bold text-brand">{index + 1}</span>
            <AuthorAvatar author={author} className="size-10 text-xs" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-semibold text-ink">{author?.fullName ?? FALLBACK_AUTHOR_NAME}</p>
              <p className="line-clamp-2 text-xs text-subtle">{describe(entry)}</p>
            </div>
            <FollowButton authorId={entry.authorId} following={entry.following} />
          </li>
        );
      })}
    </ol>
  );
}
