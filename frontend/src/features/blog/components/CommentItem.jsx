import { useState } from "react";
import { ChevronDown, Loader2, Trash2 } from "lucide-react";
import { toast } from "sonner";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogMedia,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { useRequireLogin } from "@/features/auth/hooks/useRequireLogin";
import { useAuthStore } from "@/features/auth/store/authStore";
import AuthorAvatar from "@/features/blog/components/AuthorAvatar";
import CommentComposer from "@/features/blog/components/CommentComposer";
import { useReplies } from "@/features/blog/hooks/useComments";
import { useDeleteComment } from "@/features/blog/hooks/useCommentMutations";
import { FALLBACK_AUTHOR_NAME, formatTimeAgo } from "@/features/blog/utils/blogFormat";
import { cn } from "@/lib/utils";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

const actionClass = "text-xs font-medium text-subtle transition hover:text-ink";

/**
 * Một comment (cấp 1 hoặc reply). `author` là { fullName, avatarUrl } hoặc undefined.
 * - Comment cấp 1 có replyCount > 0 sẽ có nút mở danh sách reply (chỉ gọi API khi bấm).
 * - Comment đã xóa: BE trả deleted = true, content = null -> hiện dòng mờ, giữ nguyên thread.
 * - Hành động: Phản hồi (chỉ comment gốc), Sửa (chỉ chủ comment), Xóa (chủ comment hoặc ADMIN).
 *   Khách bấm Phản hồi sẽ được đá sang /login.
 */
export default function CommentItem({ comment, author, isReply = false }) {
  const [showReplies, setShowReplies] = useState(false);
  const [replying, setReplying] = useState(false);
  const [editing, setEditing] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);

  const user = useAuthStore((s) => s.user);
  const { requireLogin } = useRequireLogin();
  const deleteComment = useDeleteComment();

  const hasReplies = !isReply && comment.replyCount > 0;
  const isOwner = user?.id === comment.authorId;
  const isAdmin = user?.role === "ADMIN";
  const canEdit = !comment.deleted && isOwner;
  const canDelete = !comment.deleted && (isOwner || isAdmin);
  const canReply = !comment.deleted && !isReply;

  const handleDelete = () => {
    deleteComment.mutate(comment.id, {
      onSuccess: () => {
        setConfirmDelete(false);
        toast.success("Đã xóa bình luận");
      },
      onError: (error) => toast.error(error.message),
    });
  };

  return (
    <li className="flex gap-3">
      <AuthorAvatar author={author} className={isReply ? "size-8 text-xs" : "size-10 text-sm"} />

      <div className="min-w-0 flex-1">
        {editing ? (
          <CommentComposer
            blogId={comment.targetId}
            commentId={comment.id}
            initialContent={comment.content ?? ""}
            autoFocus
            onDone={() => setEditing(false)}
            onCancel={() => setEditing(false)}
          />
        ) : (
          <div className="rounded-2xl bg-surface px-4 py-2.5">
            <p className="flex flex-wrap items-baseline gap-x-2 text-sm">
              <span className="font-semibold text-ink">
                {author?.fullName ?? FALLBACK_AUTHOR_NAME}
              </span>
              <span className="text-xs text-subtle">{formatTimeAgo(comment.createdAt)}</span>
            </p>
            {comment.deleted ? (
              <p className="mt-0.5 text-sm italic text-subtle">Bình luận đã bị xóa</p>
            ) : (
              <p className="mt-0.5 whitespace-pre-line break-words text-sm leading-relaxed text-body">
                {comment.content}
              </p>
            )}
          </div>
        )}

        {!editing && (canReply || canEdit || canDelete) && (
          <div className="mt-1 ml-2 flex items-center gap-3">
            {canReply && (
              <button
                type="button"
                onClick={() => requireLogin() && setReplying((open) => !open)}
                className={actionClass}
              >
                Phản hồi
              </button>
            )}
            {canEdit && (
              <button type="button" onClick={() => setEditing(true)} className={actionClass}>
                Sửa
              </button>
            )}
            {canDelete && (
              <button
                type="button"
                onClick={() => setConfirmDelete(true)}
                className={cn(actionClass, "hover:text-destructive")}
              >
                Xóa
              </button>
            )}
          </div>
        )}

        {replying && (
          <div className="mt-2">
            <CommentComposer
              blogId={comment.targetId}
              parentCommentId={comment.id}
              placeholder={`Phản hồi ${author?.fullName ?? FALLBACK_AUTHOR_NAME}...`}
              autoFocus
              onDone={() => {
                setReplying(false);
                setShowReplies(true);
              }}
              onCancel={() => setReplying(false)}
            />
          </div>
        )}

        {hasReplies && (
          <>
            <button
              type="button"
              onClick={() => setShowReplies((open) => !open)}
              aria-expanded={showReplies}
              className="mt-1.5 ml-2 flex items-center gap-1 text-xs font-medium text-brand transition hover:underline"
            >
              <ChevronDown
                className={cn("size-3.5 transition-transform", showReplies && "rotate-180")}
              />
              {showReplies ? "Ẩn phản hồi" : `Xem ${comment.replyCount} phản hồi`}
            </button>
            {showReplies && <ReplyList commentId={comment.id} />}
          </>
        )}
      </div>

      <AlertDialog open={confirmDelete} onOpenChange={setConfirmDelete}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogMedia className="bg-destructive/10 text-destructive">
              <Trash2 />
            </AlertDialogMedia>
            <AlertDialogTitle>Xóa bình luận?</AlertDialogTitle>
            <AlertDialogDescription>
              Bình luận sẽ hiển thị là “đã bị xóa”. Hành động này không thể hoàn tác.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleteComment.isPending}>Hủy</AlertDialogCancel>
            <AlertDialogAction
              variant="destructive"
              onClick={handleDelete}
              disabled={deleteComment.isPending}
            >
              {deleteComment.isPending && <Loader2 className="size-4 animate-spin" />}
              Xóa
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </li>
  );
}

function ReplyList({ commentId }) {
  const { replies, isPending, isError, error, hasNextPage, fetchNextPage, isFetchingNextPage } =
    useReplies(commentId);
  const { data: authors } = usePublicUsers(replies.map((r) => r.authorId));

  if (isPending) {
    return (
      <p className="mt-2 flex items-center gap-1.5 text-xs text-subtle">
        <Loader2 className="size-3.5 animate-spin" />
        Đang tải phản hồi...
      </p>
    );
  }

  if (isError) {
    return (
      <p className="mt-2 rounded-xl bg-destructive/10 px-3 py-2 text-xs text-destructive">
        {error.message}
      </p>
    );
  }

  return (
    <div className="mt-3">
      <ul className="space-y-3 border-l-2 border-border pl-3">
        {replies.map((reply) => (
          <CommentItem
            key={reply.id}
            comment={reply}
            author={authors?.get(reply.authorId)}
            isReply
          />
        ))}
      </ul>
      {hasNextPage && (
        <button
          type="button"
          onClick={() => fetchNextPage()}
          disabled={isFetchingNextPage}
          className="mt-2 ml-2 text-xs font-medium text-brand transition hover:underline disabled:opacity-60"
        >
          {isFetchingNextPage ? "Đang tải..." : "Xem thêm phản hồi"}
        </button>
      )}
    </div>
  );
}
