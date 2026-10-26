import { useState } from "react";
import {
  MessageSquare,
  Plus,
  PanelLeftClose,
  PanelLeft,
  Trash2,
} from "lucide-react";

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
import { Button } from "@/components/ui/button";
import { formatRelativeTime } from "@/features/chatbot/utils/chatUtils";
import { cn } from "@/lib/utils";

export default function ChatSidebar({
  sessions,
  activeSessionId,
  collapsed,
  onToggleCollapsed,
  onSelectSession,
  onNewChat,
  onDeleteSession,
}) {
  // Một hộp thoại xác nhận dùng chung cho mọi dòng. Tách open và pendingDelete
  // để tiêu đề không bị trống trong lúc hộp thoại đang mờ dần khi đóng.
  const [pendingDelete, setPendingDelete] = useState(null);
  const [deleteOpen, setDeleteOpen] = useState(false);

  const handleDelete = (session) => {
    setPendingDelete(session);
    setDeleteOpen(true);
  };

  const confirmDelete = () => {
    if (pendingDelete) onDeleteSession(pendingDelete.id);
    setDeleteOpen(false);
  };

  if (collapsed) {
    return (
      <div className="flex w-14 shrink-0 flex-col items-center gap-3 border-r border-border bg-surface/60 py-4">
        <Button
          type="button"
          variant="ghost"
          size="icon-lg"
          onClick={onToggleCollapsed}
          aria-label="Mở rộng lịch sử trò chuyện"
        >
          <PanelLeft className="size-4.5" />
        </Button>
        <Button
          type="button"
          size="icon-lg"
          onClick={onNewChat}
          aria-label="Đoạn chat mới"
        >
          <Plus className="size-4.5" />
        </Button>
      </div>
    );
  }

  return (
    <aside className="flex w-72 shrink-0 flex-col border-r border-border bg-surface/60">
      <div className="flex items-center justify-between px-4 pt-4">
        <h2 className="text-xs font-semibold tracking-wide text-subtle">
          LỊCH SỬ TRÒ CHUYỆN
        </h2>
        <Button
          type="button"
          variant="ghost"
          size="icon-sm"
          onClick={onToggleCollapsed}
          aria-label="Thu gọn lịch sử trò chuyện"
          className="rounded-md"
        >
          <PanelLeftClose className="size-4" />
        </Button>
      </div>

      <div className="px-4 pt-3">
        <Button
          type="button"
          size="md"
          onClick={onNewChat}
          className="w-full rounded-2xl"
        >
          <Plus className="size-4" />
          Đoạn chat mới
        </Button>
      </div>

      <nav className="mt-3 flex-1 space-y-1 overflow-y-auto px-3 pb-4">
        {sessions.length === 0 && (
          <p className="px-2 py-6 text-center text-sm text-subtle">
            Chưa có đoạn chat nào.
          </p>
        )}
        {sessions.map((session) => {
          const isActive = session.id === activeSessionId;
          return (
            <div
              key={session.id}
              className={cn(
                "group relative flex items-center rounded-xl transition",
                isActive
                  ? "bg-brand-soft text-brand"
                  : "hover:bg-surface"
              )}
            >
              <button
                type="button"
                onClick={() => onSelectSession(session.id)}
                aria-current={isActive}
                className={cn(
                  "flex min-w-0 flex-1 items-center gap-2 py-2.5 pl-3 pr-8 text-left text-sm",
                  isActive ? "text-brand" : "text-body hover:text-ink"
                )}
              >
                <MessageSquare className="h-4 w-4 shrink-0" />
                <span className="min-w-0 flex-1 truncate">{session.title}</span>
                <span className="shrink-0 text-[11px] text-subtle group-hover:hidden">
                  {formatRelativeTime(session.updatedAt)}
                </span>
              </button>

              <button
                type="button"
                onClick={() => handleDelete(session)}
                aria-label={`Xoá "${session.title}"`}
                className="absolute right-1.5 hidden size-7 shrink-0 place-items-center rounded-full text-subtle transition hover:bg-destructive/10 hover:text-destructive group-hover:grid"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          );
        })}
      </nav>

      <AlertDialog open={deleteOpen} onOpenChange={setDeleteOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogMedia className="bg-destructive/10 text-destructive">
              <Trash2 />
            </AlertDialogMedia>
            <AlertDialogTitle>Xoá đoạn chat?</AlertDialogTitle>
            <AlertDialogDescription>
              “{pendingDelete?.title}” sẽ bị xoá khỏi lịch sử. Hành động này
              không thể hoàn tác.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Huỷ</AlertDialogCancel>
            <AlertDialogAction variant="destructive" onClick={confirmDelete}>
              Xoá
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </aside>
  );
}
