import { useMemo, useState } from "react";
import {
  AlertTriangle,
  Ban,
  Check,
  CheckCircle2,
  Clock,
  ExternalLink,
  Eye,
  FileText,
  Filter,
  Info,
  MessageSquare,
  Percent,
  RefreshCw,
  RotateCcw,
  Search,
  ShieldAlert,
  Sparkles,
  Video,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { useQueryClient } from "@tanstack/react-query";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import ModerationDetailDialog from "@/features/admin/moderation/components/ModerationDetailDialog";
import ReviewDecisionDialog from "@/features/admin/moderation/components/ReviewDecisionDialog";
import { MOCK_MODERATION_CASES } from "@/features/admin/moderation/data/mockModerationData";
import {
  useDismissModeration,
  usePendingModerationCases,
  useReviewModeration,
} from "@/features/admin/moderation/hooks/useModeration";
import { moderationKeys } from "@/features/admin/moderation/queryKeys";
import { cn } from "@/lib/utils";

// Nhãn và badge tương ứng cho loại nội dung (BLOG, VIDEO, COMMENT)
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
      dateStyle: "short",
      timeStyle: "short",
    }).format(d);
  } catch {
    return isoString;
  }
}

/**
 * Trang kiểm duyệt nội dung của Admin (/admin/moderation):
 * - Hàng đợi các case cần duyệt (REVIEW_REQUIRED, cũ nhất trước).
 * - Hiển thị: caseId, loại nội dung (BLOG, VIDEO, COMMENT), externalContentId, authorId, content (nội dung bị gắn cờ), categories, reason, confidence.
 * - Hỗ trợ chế độ Mock Data để test giao diện và luồng duyệt/từ chối ngay cả khi BE chưa có dữ liệu.
 */
export default function AdminModerationScreen() {
  const queryClient = useQueryClient();
  const { data: realCases = [], isPending, isError, error, isFetching } = usePendingModerationCases();
  const reviewMutation = useReviewModeration();
  const dismissMutation = useDismissModeration();

  // Kiểm tra BE đã trả về dữ liệu thật chưa
  const hasRealData = realCases.length > 0;

  // Chế độ dữ liệu mẫu để kiểm thử (chỉ hiển thị khi BE chưa có dữ liệu thật)
  const [isMockMode, setIsMockMode] = useState(false);
  const [mockCases, setMockCases] = useState(MOCK_MODERATION_CASES);

  // Danh sách thực tế hiển thị: Khi BE đã trả dữ liệu thật, luôn ưu tiên hiển thị dữ liệu thật
  const activeCases = hasRealData ? realCases : (isMockMode ? mockCases : realCases);

  // Bộ lọc và tìm kiếm
  const [searchQuery, setSearchQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState("ALL"); // ALL, BLOG, VIDEO, COMMENT

  // Modal quyết định duyệt / từ chối
  const [activeModal, setActiveModal] = useState({
    item: null,
    decision: null, // "APPROVED" | "REJECTED" | "DISMISSED"
  });

  // Modal xem chi tiết
  const [detailItem, setDetailItem] = useState(null);

  const handleReviewConfirm = ({ id, decision, reason }) => {
    if (!hasRealData && isMockMode) {
      // Giả lập xử lý khi dùng dữ liệu mẫu
      setTimeout(() => {
        setMockCases((prev) => prev.filter((c) => c.caseId !== id));
        toast.success(
          decision === "APPROVED"
            ? `[Demo Test] Đã duyệt thành công case #${id}${reason ? ` (Lý do: ${reason})` : ""}`
            : decision === "DISMISSED"
              ? `[Demo Test] Đã bỏ qua case #${id}${reason ? ` (Lý do: ${reason})` : ""}`
              : `[Demo Test] Đã từ chối thành công case #${id}${reason ? ` (Lý do: ${reason})` : ""}`
        );
        setActiveModal({ item: null, decision: null });
      }, 300);
      return;
    }

    (decision === "DISMISSED" ? dismissMutation : reviewMutation).mutate(
      { id, decision, reason },
      {
        onSuccess: () => {
          toast.success(
            decision === "APPROVED"
              ? `Đã duyệt thành công case #${id}`
              : decision === "DISMISSED"
                ? `Đã bỏ qua case #${id}, nội dung gốc không bị thay đổi`
                : `Đã từ chối thành công case #${id}`
          );
          setActiveModal({ item: null, decision: null });
        },
        onError: (err) => {
          toast.error(err.message || "Có lỗi xảy ra khi cập nhật quyết định");
          // Khi gặp lỗi 6013 (Case đã được xử lý bởi admin khác), đóng modal và làm mới hàng đợi
          if (err?.code === 6013) {
            setActiveModal({ item: null, decision: null });
            queryClient.invalidateQueries({ queryKey: moderationKeys.all });
          }
        },
      }
    );
  };

  const handleRefresh = () => {
    if (!hasRealData && isMockMode) {
      setMockCases(MOCK_MODERATION_CASES);
      toast.info("Đã làm mới dữ liệu mẫu.");
    } else {
      queryClient.invalidateQueries({ queryKey: moderationKeys.all });
    }
  };

  // Lọc danh sách theo từ khóa tìm kiếm và loại nội dung
  const filteredCases = useMemo(() => {
    return activeCases.filter((c) => {
      // Lọc theo loại
      if (typeFilter !== "ALL") {
        if (typeFilter === "UNKNOWN") {
          if (c.contentType) return false;
        } else if (c.contentType !== typeFilter) {
          return false;
        }
      }

      // Lọc theo từ khóa (Mã case, ID gốc, Mã tác giả, nội dung bị gắn cờ, categories, lý do)
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase().trim();
        const matchCaseId = String(c.caseId).includes(query);
        const matchExternalId = c.externalContentId != null && String(c.externalContentId).includes(query);
        const matchAuthorId = c.authorId != null && String(c.authorId).includes(query);
        const matchContent = c.content && c.content.toLowerCase().includes(query);
        const matchReason = c.reason && c.reason.toLowerCase().includes(query);
        const matchCategories = c.categories && c.categories.some((cat) => cat.toLowerCase().includes(query));
        const matchType = c.contentType && c.contentType.toLowerCase().includes(query);

        return (
          matchCaseId ||
          matchExternalId ||
          matchAuthorId ||
          matchContent ||
          matchReason ||
          matchCategories ||
          matchType
        );
      }

      return true;
    });
  }, [activeCases, searchQuery, typeFilter]);

  return (
    <div className="flex flex-col gap-6">
      {/* Header */}
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="font-heading text-3xl font-bold text-ink">Kiểm duyệt nội dung</h1>
            {activeCases.length > 0 && (
              <span className="flex items-center rounded-full bg-warning/15 px-2.5 py-0.5 text-xs font-semibold text-warning">
                {activeCases.length} chờ duyệt
              </span>
            )}
            {!hasRealData && isMockMode && (
              <span className="flex items-center gap-1 rounded-full bg-amber-500/10 px-2.5 py-0.5 text-xs font-semibold text-amber-600 dark:text-amber-400 border border-amber-500/20">
                <Sparkles className="size-3" />
                Chế độ Test Demo
              </span>
            )}
          </div>
          <p className="mt-1 text-sm text-subtle">
            Hàng đợi các nội dung nghi ngờ vi phạm hoặc cần con người kiểm duyệt (từ AI Moderation).
          </p>
        </div>

        <div className="flex items-center gap-2">
          {/* Nút bật/tắt Mock Mode chỉ hiển thị khi BE chưa có dữ liệu thật */}
          {!hasRealData && (
            <Button
              type="button"
              variant={isMockMode ? "secondary" : "outline"}
              size="sm"
              onClick={() => setIsMockMode((prev) => !prev)}
              className="gap-1.5 text-xs"
            >
              <Sparkles className="size-3.5 text-amber-500" />
              {isMockMode ? "Tắt dữ liệu mẫu" : "Dữ liệu mẫu (Demo)"}
            </Button>
          )}

          {!hasRealData && isMockMode && (
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => {
                setMockCases(MOCK_MODERATION_CASES);
                toast.info("Đã khôi phục dữ liệu mẫu ban đầu.");
              }}
              className="gap-1 text-xs"
              title="Khôi phục lại dữ liệu mẫu"
            >
              <RotateCcw className="size-3.5" />
              Khôi phục mẫu
            </Button>
          )}

          <Button
            type="button"
            variant="outline"
            size="sm"
            disabled={!isMockMode && isFetching}
            onClick={handleRefresh}
          >
            <RefreshCw className={cn("size-4", !isMockMode && isFetching && "animate-spin")} />
            Làm mới
          </Button>
        </div>
      </div>

      {/* Thông tin giải thích cơ chế kiểm duyệt */}
      <div className="flex items-start gap-3 rounded-2xl border border-border bg-card p-4 text-xs text-subtle shadow-sm">
        <Info className="mt-0.5 size-4 shrink-0 text-brand" />
        <div className="space-y-1">
          <p className="font-semibold text-ink">Quy trình kiểm duyệt tự động & đồng bộ:</p>
          <p className="leading-relaxed">
            • Khi quản trị viên chọn <strong className="text-brand">Duyệt</strong> hoặc <strong className="text-destructive">Từ chối</strong>, AI-Service sẽ tự động đồng bộ quyết định sang Blog-Service để công khai hoặc gỡ bỏ nội dung.
          </p>
          <p className="leading-relaxed">
            • Quản trị viên có thể nhấp trực tiếp vào mã ID gốc (<code className="rounded bg-surface px-1 py-0.5 font-mono text-[11px] text-ink">externalContentId</code>) của bài viết để xem toàn bộ nội dung (bao gồm cả bài viết chưa xuất bản).
          </p>
        </div>
      </div>

      {/* Trạng thái lỗi (khi không bật mock mode) */}
      {!isMockMode && isError && (
        <div
          role="alert"
          className="flex items-start gap-2 rounded-2xl bg-destructive/10 p-4 text-sm text-destructive"
        >
          <AlertTriangle className="size-5 shrink-0" />
          <div className="flex-1">
            <p>{error?.message || "Không thể tải danh sách kiểm duyệt từ Backend."}</p>
            <p className="mt-1 text-xs text-destructive/80">
              Bạn có thể nhấn nút <strong>"Dữ liệu mẫu (Demo)"</strong> phía trên để kiểm tra giao diện và chức năng duyệt/từ chối.
            </p>
          </div>
          <Button
            type="button"
            variant="outline"
            size="sm"
            onClick={() => setIsMockMode(true)}
            className="shrink-0 gap-1 bg-card text-xs text-ink"
          >
            <Sparkles className="size-3.5 text-amber-500" />
            Bật dữ liệu mẫu
          </Button>
        </div>
      )}

      {/* Bộ lọc và tìm kiếm */}
      {(!isPending || isMockMode) && activeCases.length > 0 && (
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="relative min-w-60 flex-1 max-w-sm">
            <Search className="absolute left-3 top-1/2 size-4 -translate-y-1/2 text-subtle" />
            <Input
              type="search"
              placeholder="Tìm theo mã case, ID gốc, tác giả, nội dung, lý do..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9 text-xs rounded-xl"
            />
          </div>

          <div className="flex items-center gap-1.5 overflow-x-auto text-xs">
            <span className="flex items-center gap-1 text-subtle mr-1">
              <Filter className="size-3.5" /> Lọc:
            </span>
            {[
              { id: "ALL", label: `Tất cả (${activeCases.length})` },
              { id: "BLOG", label: `Bài viết (${activeCases.filter((c) => c.contentType === "BLOG").length})` },
              { id: "VIDEO", label: `Video (${activeCases.filter((c) => c.contentType === "VIDEO").length})` },
              { id: "COMMENT", label: `Bình luận (${activeCases.filter((c) => c.contentType === "COMMENT").length})` },
            ].map(({ id, label }) => (
              <button
                key={id}
                type="button"
                onClick={() => setTypeFilter(id)}
                className={cn(
                  "rounded-full px-3 py-1 font-medium transition",
                  typeFilter === id
                    ? "bg-brand text-brand-foreground"
                    : "bg-surface text-subtle hover:text-ink"
                )}
              >
                {label}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Trạng thái đang tải */}
      {!isMockMode && isPending ? (
        <div aria-hidden className="flex flex-col gap-3">
          {[0, 1, 2, 3].map((i) => (
            <div key={i} className="h-28 animate-pulse rounded-3xl border border-border bg-card" />
          ))}
        </div>
      ) : activeCases.length === 0 ? (
        /* Trạng thái rỗng */
        <div className="flex flex-col items-center justify-center rounded-3xl border border-dashed border-border bg-card p-12 text-center">
          <div className="flex size-12 items-center justify-center rounded-full bg-brand-soft text-brand">
            <CheckCircle2 className="size-6" />
          </div>
          <h3 className="mt-4 font-heading text-lg font-bold text-ink">Hàng đợi đang trống</h3>
          <p className="mt-1 max-w-md text-sm text-subtle">
            Hiện tại không có nội dung nào cần kiểm duyệt thủ công.
          </p>
          {!isMockMode && (
            <div className="mt-5">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setIsMockMode(true)}
                className="gap-2 rounded-xl text-xs"
              >
                <Sparkles className="size-4 text-amber-500" />
                Nạp dữ liệu mẫu để test giao diện và chức năng
              </Button>
            </div>
          )}
          {isMockMode && (
            <div className="mt-5">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setMockCases(MOCK_MODERATION_CASES)}
                className="gap-2 rounded-xl text-xs"
              >
                <RotateCcw className="size-4" />
                Nạp lại danh sách dữ liệu mẫu
              </Button>
            </div>
          )}
        </div>
      ) : filteredCases.length === 0 ? (
        <div className="rounded-3xl border border-border bg-card p-8 text-center text-sm text-subtle">
          Không tìm thấy case kiểm duyệt nào phù hợp với bộ lọc hiện tại.
        </div>
      ) : (
        /* Bảng danh sách hàng đợi */
        <div className="overflow-hidden rounded-3xl border border-border bg-card shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="border-b border-border bg-surface text-xs font-semibold text-subtle">
                <tr>
                  <th scope="col" className="px-4 py-3.5">Mã Case</th>
                  <th scope="col" className="px-4 py-3.5">Loại</th>
                  <th scope="col" className="px-4 py-3.5">ID Gốc</th>
                  <th scope="col" className="px-4 py-3.5">Mã Tác Giả</th>
                  <th scope="col" className="px-4 py-3.5">Nội dung bị gắn cờ</th>
                  <th scope="col" className="px-4 py-3.5">Danh mục vi phạm</th>
                  <th scope="col" className="px-4 py-3.5">Lý do từ AI</th>
                  <th scope="col" className="px-4 py-3.5 text-center">Độ tin cậy</th>
                  <th scope="col" className="px-4 py-3.5">Thời gian gửi</th>
                  <th scope="col" className="px-4 py-3.5 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {filteredCases.map((c) => {
                  const typeMeta = CONTENT_TYPE_MAP[c.contentType] || {
                    label: c.contentType || "Chưa phân loại",
                    icon: ShieldAlert,
                    className: "bg-surface text-subtle",
                  };
                  const Icon = typeMeta.icon;

                  return (
                    <tr key={c.caseId} className="transition hover:bg-surface/50">
                      {/* Case ID */}
                      <td className="px-4 py-4 font-mono font-semibold text-ink">
                        #{c.caseId}
                      </td>

                      {/* Loại nội dung */}
                      <td className="px-4 py-4">
                        <span
                          className={cn(
                            "inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium",
                            typeMeta.className
                          )}
                        >
                          <Icon className="size-3.5" />
                          {typeMeta.label}
                        </span>
                      </td>

                      {/* Mã ID gốc (externalContentId) */}
                      <td className="px-4 py-4 font-mono text-xs text-subtle">
                        {c.externalContentId != null ? (
                          c.contentType === "BLOG" ? (
                            <a
                              href={`/blog/${c.externalContentId}`}
                              target="_blank"
                              rel="noreferrer"
                              className="inline-flex items-center gap-1 font-semibold text-ink underline hover:text-brand"
                              title="Mở bài viết trong tab mới (Admin có quyền xem bài chưa đăng)"
                            >
                              #{c.externalContentId}
                              <ExternalLink className="size-3 text-subtle" />
                            </a>
                          ) : (
                            <span className="font-semibold text-ink">#{c.externalContentId}</span>
                          )
                        ) : (
                          <span>—</span>
                        )}
                      </td>

                      {/* Mã tác giả (authorId) */}
                      <td className="px-4 py-4 font-mono text-xs text-subtle">
                        {c.authorId != null ? (
                          <span className="font-semibold text-ink">#{c.authorId}</span>
                        ) : (
                          <span>—</span>
                        )}
                      </td>

                      {/* Flagged Content */}
                      <td className="max-w-xs px-4 py-4">
                        {c.content ? (
                          <p className="line-clamp-2 text-xs italic text-body" title={c.content}>
                            "{c.content}"
                          </p>
                        ) : (
                          <span className="text-xs text-subtle italic">Không có</span>
                        )}
                      </td>

                      {/* Categories */}
                      <td className="px-4 py-4">
                        {c.categories && c.categories.length > 0 ? (
                          <div className="flex flex-wrap gap-1">
                            {c.categories.map((cat) => (
                              <span
                                key={cat}
                                className="inline-block rounded-md bg-destructive/10 px-2 py-0.5 text-xs font-medium text-destructive"
                              >
                                {cat}
                              </span>
                            ))}
                          </div>
                        ) : (
                          <span className="text-xs text-subtle">Không có</span>
                        )}
                      </td>

                      {/* Reason */}
                      <td className="max-w-xs px-4 py-4">
                        <p className="line-clamp-2 text-xs text-body" title={c.reason}>
                          {c.reason || "Cần quản trị viên kiểm tra và đưa ra quyết định."}
                        </p>
                      </td>

                      {/* Confidence */}
                      <td className="px-4 py-4 text-center">
                        <span className="inline-flex items-center gap-1 rounded-full bg-surface px-2.5 py-0.5 font-mono text-xs font-medium text-ink">
                          <Percent className="size-3 text-subtle" />
                          {formatConfidence(c.confidence)}
                        </span>
                      </td>

                      {/* Created At */}
                      <td className="px-4 py-4 whitespace-nowrap text-xs text-subtle">
                        <span className="inline-flex items-center gap-1">
                          <Clock className="size-3.5 text-subtle" />
                          {formatDateTime(c.createdAt)}
                        </span>
                      </td>

                      {/* Thao tác */}
                      <td className="px-4 py-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <Button
                            type="button"
                            size="sm"
                            variant="outline"
                            onClick={() => setDetailItem(c)}
                            className="h-8 gap-1 rounded-xl px-2.5 text-xs text-subtle hover:text-ink"
                            title="Xem chi tiết case kiểm duyệt"
                          >
                            <Eye className="size-3.5" />
                            <span className="hidden sm:inline">Chi tiết</span>
                          </Button>

                          <Button
                            type="button"
                            size="sm"
                            variant="outline"
                            onClick={() => setActiveModal({ item: c, decision: "DISMISSED" })}
                            className="h-8 gap-1 rounded-xl px-2.5 text-xs text-subtle hover:text-ink"
                            title="Chỉ đưa ca ra khỏi hàng đợi, nội dung gốc không bị đổi trạng thái"
                          >
                            <Ban className="size-3.5" />
                            Bỏ qua
                          </Button>

                          <Button
                            type="button"
                            size="sm"
                            variant="default"
                            onClick={() =>
                              setActiveModal({
                                item: c,
                                decision: "APPROVED",
                              })
                            }
                            className="h-8 gap-1 rounded-xl px-3"
                          >
                            <Check className="size-3.5" />
                            Duyệt
                          </Button>

                          <Button
                            type="button"
                            size="sm"
                            variant="destructive"
                            onClick={() =>
                              setActiveModal({
                                item: c,
                                decision: "REJECTED",
                              })
                            }
                            className="h-8 gap-1 rounded-xl px-3"
                          >
                            <X className="size-3.5" />
                            Từ chối
                          </Button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Dialog chi tiết case kiểm duyệt */}
      <ModerationDetailDialog
        open={Boolean(detailItem)}
        item={detailItem}
        onOpenChange={(open) => {
          if (!open) setDetailItem(null);
        }}
        onDismiss={(item) => {
          setActiveModal({ item, decision: "DISMISSED" });
        }}
        onApprove={(item) => {
          setActiveModal({ item, decision: "APPROVED" });
        }}
        onReject={(item) => {
          setActiveModal({ item, decision: "REJECTED" });
        }}
      />

      {/* Dialog xác nhận duyệt / từ chối */}
      <ReviewDecisionDialog
        open={Boolean(activeModal.item && activeModal.decision)}
        item={activeModal.item}
        decision={activeModal.decision}
        loading={!isMockMode && (reviewMutation.isPending || dismissMutation.isPending)}
        onOpenChange={(open) => {
          if (!open) setActiveModal({ item: null, decision: null });
        }}
        onConfirm={handleReviewConfirm}
      />
    </div>
  );
}
