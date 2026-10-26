import {
  Ban,
  Check,
  ExternalLink,
  FileText,
  MessageSquare,
  Percent,
  ShieldAlert,
  Video,
  X,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { cn } from "@/lib/utils";

const CONTENT_TYPE_MAP = {
  BLOG: { label: "Bài viết", icon: FileText, className: "bg-blue-500/10 text-blue-600 dark:text-blue-400" },
  VIDEO: { label: "Video", icon: Video, className: "bg-purple-500/10 text-purple-600 dark:text-purple-400" },
  COMMENT: { label: "Bình luận", icon: MessageSquare, className: "bg-amber-500/10 text-amber-600 dark:text-amber-400" },
};

function formatConfidence(confidence) {
  if (confidence == null) return "—";
  const num = typeof confidence === "number" ? confidence : parseFloat(confidence);
  if (Number.isNaN(num)) return "—";
  return `${(num * 100).toFixed(1)}%`;
}

function formatDateTime(isoString) {
  if (!isoString) return "—";
  try {
    const d = new Date(isoString);
    return new Intl.DateTimeFormat("vi-VN", {
      dateStyle: "full",
      timeStyle: "medium",
    }).format(d);
  } catch {
    return isoString;
  }
}

/**
 * Modal hiển thị toàn bộ thông tin chi tiết của một case kiểm duyệt.
 * Hiển thị trực tiếp nội dung văn bản bị gắn cờ (content) và mã tác giả (authorId) từ AI-Service.
 */
export default function ModerationDetailDialog({
  item,
  open,
  onOpenChange,
  onApprove,
  onReject,
  onDismiss,
}) {
  if (!item) return null;

  const typeMeta = CONTENT_TYPE_MAP[item.contentType] || {
    label: item.contentType || "Chưa phân loại",
    icon: ShieldAlert,
    className: "bg-surface text-subtle",
  };
  const Icon = typeMeta.icon;

  const hasExternalId = item.externalContentId != null;
  const isBlog = item.contentType === "BLOG";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <span className="flex size-8 shrink-0 items-center justify-center rounded-full bg-warning/15 text-warning">
              <ShieldAlert className="size-4" />
            </span>
            <DialogTitle>Chi tiết kiểm duyệt #{item.caseId}</DialogTitle>
          </div>
          <DialogDescription>
            Xem xét nội dung vi phạm thực tế và quyết định phê duyệt hoặc từ chối nội dung.
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-col gap-4 py-2 text-sm">
          {/* Thông tin thuộc tính */}
          <div className="grid grid-cols-2 gap-3 rounded-2xl border border-border bg-surface p-3.5">
            <div>
              <span className="text-xs text-subtle">Loại nội dung:</span>
              <div className="mt-1 flex items-center gap-1.5 font-medium text-ink">
                <span
                  className={cn(
                    "inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-medium",
                    typeMeta.className
                  )}
                >
                  <Icon className="size-3" />
                  {typeMeta.label}
                </span>
              </div>
            </div>

            <div>
              <span className="text-xs text-subtle">Mã ID nội dung gốc:</span>
              <div className="mt-1 flex items-center gap-1.5">
                {hasExternalId ? (
                  isBlog ? (
                    <a
                      href={`/blog/${item.externalContentId}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex items-center gap-1 font-mono text-sm font-semibold text-ink underline hover:text-brand"
                      title="Mở bài viết trong tab mới (Admin có quyền xem bài chưa đăng)"
                    >
                      #{item.externalContentId}
                      <ExternalLink className="size-3 text-subtle" />
                    </a>
                  ) : (
                    <span className="font-mono text-sm font-semibold text-ink">#{item.externalContentId}</span>
                  )
                ) : (
                  <span className="text-subtle">—</span>
                )}
              </div>
            </div>

            <div>
              <span className="text-xs text-subtle">Mã tác giả:</span>
              <p className="mt-1 font-mono text-sm font-semibold text-ink">
                {item.authorId != null ? `#${item.authorId}` : "—"}
              </p>
            </div>

            <div>
              <span className="text-xs text-subtle">Độ tin cậy AI:</span>
              <div className="mt-1 flex items-center gap-1 font-mono font-medium text-ink">
                <Percent className="size-3.5 text-subtle" />
                {formatConfidence(item.confidence)}
              </div>
            </div>

            <div className="col-span-2">
              <span className="text-xs text-subtle">Thời gian phát hiện:</span>
              <p className="mt-1 text-xs text-subtle">
                {formatDateTime(item.createdAt)}
              </p>
            </div>
          </div>

          {/* Danh mục vi phạm */}
          <div>
            <span className="text-xs font-semibold text-ink">Danh mục vi phạm nhận diện:</span>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {item.categories && item.categories.length > 0 ? (
                item.categories.map((cat) => (
                  <span
                    key={cat}
                    className="inline-block rounded-md bg-destructive/10 px-2.5 py-1 text-xs font-semibold text-destructive"
                  >
                    {cat}
                  </span>
                ))
              ) : (
                <span className="text-xs text-subtle">Không có danh mục cụ thể</span>
              )}
            </div>
          </div>

          {/* Nội dung văn bản bị gắn cờ */}
          <div>
            <div className="flex items-center justify-between">
              <span className="text-xs font-semibold text-ink">Nội dung văn bản bị gắn cờ:</span>
              {item.authorId != null && (
                <span className="text-[11px] text-subtle">
                  Tác giả: <strong className="font-mono text-ink">#{item.authorId}</strong>
                </span>
              )}
            </div>
            <div className="mt-1.5 max-h-48 overflow-y-auto whitespace-pre-wrap rounded-2xl border border-destructive/20 bg-destructive/5 p-3.5 text-xs leading-relaxed text-body selection:bg-destructive/20">
              {item.content ? (
                <p className="italic text-ink">"{item.content}"</p>
              ) : (
                <p className="italic text-subtle">Không có nội dung văn bản đính kèm.</p>
              )}
            </div>
          </div>

          {/* Lý do từ AI */}
          <div>
            <span className="text-xs font-semibold text-ink">Lý do từ AI Moderation:</span>
            <div className="mt-1.5 rounded-2xl border border-border bg-card p-3 text-xs leading-relaxed text-body">
              {item.reason || "Cần quản trị viên kiểm tra thủ công nội dung này."}
            </div>
          </div>

          {/* Xem trước toàn bộ bài viết gốc (Admin có quyền xem bài chưa đăng) */}
          {hasExternalId && isBlog && (
            <div className="flex items-start justify-between gap-3 rounded-2xl border border-border bg-surface p-3.5 text-xs">
              <div className="space-y-0.5">
                <span className="font-semibold text-ink">Bài viết gốc #{item.externalContentId}:</span>
                <p className="text-subtle">
                  Quản trị viên có thể xem trực tiếp toàn bộ bài viết trên trang chi tiết (bao gồm cả bài viết chưa xuất bản).
                </p>
              </div>
              <a
                href={`/blog/${item.externalContentId}`}
                target="_blank"
                rel="noreferrer"
                className="inline-flex shrink-0 items-center gap-1.5 rounded-xl border border-border bg-card px-3 py-1.5 font-medium text-ink shadow-sm transition hover:bg-surface hover:text-brand"
              >
                <span>Mở bài viết</span>
                <ExternalLink className="size-3.5 text-subtle" />
              </a>
            </div>
          )}
        </div>

        <p className="text-[11px] leading-relaxed text-subtle">
          <strong className="text-ink">Bỏ qua</strong>: chỉ đưa ca ra khỏi hàng đợi, nội dung gốc không bị đổi trạng thái
          (khác với <strong className="text-ink">Từ chối</strong>).
        </p>

        <DialogFooter className="gap-2 sm:gap-0">
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
          >
            Đóng
          </Button>

          <Button
            type="button"
            variant="outline"
            title="Chỉ đưa ca ra khỏi hàng đợi, nội dung gốc không bị đổi trạng thái"
            onClick={() => {
              onOpenChange(false);
              onDismiss(item);
            }}
            className="gap-1"
          >
            <Ban className="size-3.5" />
            Bỏ qua
          </Button>

          <Button
            type="button"
            variant="destructive"
            onClick={() => {
              onOpenChange(false);
              onReject(item);
            }}
            className="gap-1"
          >
            <X className="size-3.5" />
            Từ chối
          </Button>

          <Button
            type="button"
            variant="default"
            onClick={() => {
              onOpenChange(false);
              onApprove(item);
            }}
            className="gap-1"
          >
            <Check className="size-3.5" />
            Duyệt nội dung
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
