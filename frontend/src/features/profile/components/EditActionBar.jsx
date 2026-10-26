import { Clock, Loader2, Save } from "lucide-react";

import { Button } from "@/components/ui/button";
import { errorBoxClass, successBoxClass } from "@/features/profile/utils/editProfileConstants";

/** Thanh hành động cuối trang: Hủy thay đổi / Lưu thông tin. */
export default function EditActionBar({ status, saving, onSave, onCancel }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-4 pt-4 border-t border-border text-xs text-subtle">
      <div className="flex items-center gap-1.5">
        <Clock className="h-3.5 w-3.5" />
        <span>Chỉ các phần đã thay đổi (thông tin cá nhân, dị ứng) sẽ được lưu</span>
      </div>

      <div className="flex flex-wrap items-center gap-3">
        {status.message && (
          <span className={status.type === "error" ? errorBoxClass : successBoxClass}>
            {status.message}
          </span>
        )}
        <Button
          type="button"
          variant="secondary"
          size="default"
          onClick={onCancel}
          disabled={saving}
          className="rounded-full px-5 font-semibold cursor-pointer"
        >
          Hủy thay đổi
        </Button>
        <Button
          type="button"
          variant="default"
          size="default"
          onClick={onSave}
          disabled={saving}
          className="rounded-full gap-1.5 px-6 font-semibold shadow-sm cursor-pointer"
        >
          {saving ? (
            <Loader2 className="h-3.5 w-3.5 animate-spin" />
          ) : (
            <Save className="h-3.5 w-3.5" />
          )}
          {saving ? "Đang lưu…" : "Lưu thông tin"}
        </Button>
      </div>
    </div>
  );
}
