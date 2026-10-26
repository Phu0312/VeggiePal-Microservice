import { MessageSquare } from "lucide-react";

// BE từ chối targetType=VIDEO với mã lỗi UNSUPPORTED_TARGET_TYPE.
// Vì vậy phần bình luận được hiển thị thông báo trạng thái tĩnh, không gọi API bình luận để tránh lỗi.
export default function CommentsHeader() {
  return (
    <div className="flex flex-col gap-3 rounded-2xl border border-dashed border-border p-4 text-center">
      <div className="flex items-center justify-center gap-2 text-sm font-semibold text-subtle">
        <MessageSquare className="size-4" />
        Bình luận video
      </div>
      <p className="text-xs text-subtle">
        Tính năng bình luận và thảo luận dưới video đang được hoàn thiện và sẽ sớm ra mắt.
      </p>
    </div>
  );
}
