import { useMemo, useState } from "react";

import {
  useAllergens,
  useMyAllergies,
  useReplaceMyAllergies,
} from "@/features/profile/hooks/useAllergies";
import { groupAllergens } from "@/features/profile/utils/editProfileHelpers";

/**
 * Lựa chọn dị ứng đang chỉnh. draft = null nghĩa là user chưa chỉnh gì
 * -> hiển thị đúng dữ liệu server. Là hook riêng vì nút lưu cuối trang cũng cần dùng.
 */
export function useAllergyDraft() {
  const allergensQuery = useAllergens();
  const myQuery = useMyAllergies();
  const replace = useReplaceMyAllergies();
  const [draft, setDraft] = useState(null);

  const savedIds = useMemo(
    () => new Set((myQuery.data ?? []).map((a) => a.id)),
    [myQuery.data]
  );
  const selectedIds = draft ?? savedIds;
  const dirty =
    selectedIds.size !== savedIds.size || [...selectedIds].some((id) => !savedIds.has(id));

  const groups = useMemo(() => groupAllergens(allergensQuery.data), [allergensQuery.data]);

  // Chọn/bỏ chọn theo allergenId (không dùng tên) để không lệch khi đổi tên hiển thị.
  const toggle = (id) => {
    replace.reset(); // ẩn thông báo cũ của lần lưu trước
    setDraft((prev) => {
      const next = new Set(prev ?? savedIds);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const save = async () => {
    await replace.mutateAsync([...selectedIds]); // mảng rỗng = xóa hết
    setDraft(null);
  };

  return {
    groups,
    loading: allergensQuery.isPending || myQuery.isPending,
    loadError: allergensQuery.error || myQuery.error,
    selectedIds,
    dirty,
    toggle,
    save,
    mutation: replace,
    discard: () => setDraft(null),
  };
}
