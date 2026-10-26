import { AlertTriangle, Loader2, Save } from "lucide-react";

import { Button } from "@/components/ui/button";
import EditAllergyGroup from "@/features/profile/components/EditAllergyGroup";
import { errorBoxClass, successBoxClass } from "@/features/profile/utils/editProfileConstants";

/** Box "Thực phẩm dị ứng" — nhận state từ useAllergyDraft. */
export default function EditAllergyCard({ allergy }) {
  const { groups, loading, loadError, selectedIds, dirty, toggle, mutation } = allergy;
  const ready = !loading && !loadError && groups.length > 0;

  return (
    <div className="rounded-3xl border border-border bg-card p-6 shadow-sm space-y-4">
      <div className="flex items-center gap-2.5">
        <div className="flex h-9 w-9 items-center justify-center rounded-2xl bg-warning/10 text-warning">
          <AlertTriangle className="h-5 w-5" />
        </div>
        <div>
          <h3 className="text-sm font-bold text-ink">
            Thực phẩm dị ứng & Kiêng khem
          </h3>
          <p className="text-[11px] text-subtle">
            Chọn các thành phần thực phẩm bạn cần tránh để thực đơn lọc tự động
          </p>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center gap-2 py-8 text-xs text-subtle">
          <Loader2 className="h-4 w-4 animate-spin text-brand" />
          Đang tải danh mục dị ứng…
        </div>
      ) : loadError ? (
        <p className={errorBoxClass}>{loadError.message || "Không tải được danh mục dị ứng"}</p>
      ) : groups.length === 0 ? (
        <p className="py-4 text-center text-xs text-subtle">Chưa có danh mục dị ứng nào.</p>
      ) : (
        <div className="space-y-3 pt-2">
          {groups.map(([category, items], index) => (
            <EditAllergyGroup
              key={category}
              category={category}
              items={items}
              index={index}
              selectedIds={selectedIds}
              onToggle={toggle}
            />
          ))}
        </div>
      )}

      {mutation.isError && (
        <p className={errorBoxClass}>{mutation.error?.message || "Cập nhật dị ứng thất bại"}</p>
      )}
      {mutation.isSuccess && !dirty && (
        <p className={successBoxClass}>Đã cập nhật danh sách dị ứng.</p>
      )}

      {ready && (
        <Button
          type="button"
          size="lg"
          className="rounded-xl"
          onClick={() => allergy.save().catch(() => {})}
          disabled={mutation.isPending || !dirty}
        >
          {mutation.isPending ? (
            <Loader2 className="size-4 animate-spin" />
          ) : (
            <Save className="size-4" />
          )}
          Lưu dị ứng
        </Button>
      )}
    </div>
  );
}
