import { useEffect, useRef, useState } from "react";
import { ChevronLeft, ChevronRight, Leaf, Pencil, Plus, Search, TriangleAlert, Trash2 } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import IngredientFormDialog from "@/features/admin/components/IngredientFormDialog";
import { useDeleteIngredient } from "@/features/ingredient/hooks/useIngredientMutations";
import { useIngredients } from "@/features/ingredient/hooks/useIngredients";
import ConfirmDialog from "@/shared/components/ConfirmDialog";
import SelectField from "@/shared/components/SelectField";

const PAGE_SIZE = 10;
const SEARCH_DEBOUNCE_MS = 400;

const VEGAN_OPTIONS = [
  { value: "", label: "Mọi loại" },
  { value: "true", label: "Thuần chay" },
  { value: "false", label: "Không thuần chay" },
];

const ALLERGEN_OPTIONS = [
  { value: "", label: "Dị ứng: tất cả" },
  { value: "true", label: "Có thể gây dị ứng" },
  { value: "false", label: "Không gây dị ứng" },
];

// Giá trị của dropdown lọc -> tham số boolean của BE ("" = không lọc).
const toBool = (value) => (value === "" ? undefined : value === "true");

const num = (value) => (value == null ? "—" : Number(value));

// Trang quản lý nguyên liệu (/admin/ingredients): tìm kiếm, lọc, phân trang, thêm / sửa / xóa.
// Lưu ý: BE chỉ trả nguyên liệu đang hoạt động nên danh sách này không có nguyên liệu đã tắt.
export default function AdminIngredientsScreen() {
  const [text, setText] = useState("");
  const [keyword, setKeyword] = useState("");
  const [vegan, setVegan] = useState("");
  const [allergen, setAllergen] = useState("");
  const [page, setPage] = useState(0);
  const timerRef = useRef(undefined);

  const [formTarget, setFormTarget] = useState(null);
  const [deleting, setDeleting] = useState(null);

  const { data, isPending, isError, error, isFetching } = useIngredients({
    keyword,
    vegan: toBool(vegan),
    allergen: toBool(allergen),
    page,
    size: PAGE_SIZE,
  });
  const deleteIngredient = useDeleteIngredient();

  useEffect(() => () => clearTimeout(timerRef.current), []);

  const handleSearch = (event) => {
    const value = event.target.value;
    setText(value);
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      setKeyword(value.trim());
      setPage(0);
    }, SEARCH_DEBOUNCE_MS);
  };

  const handleFilter = (setter) => (value) => {
    setter(value);
    setPage(0);
  };

  const handleDelete = () =>
    deleteIngredient.mutate(deleting.id, {
      onSuccess: () => {
        setDeleting(null);
        toast.success("Đã xóa nguyên liệu");
      },
      onError: (err) => {
        setDeleting(null);
        toast.error(err.message);
      },
    });

  const items = data?.content ?? [];

  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h1 className="font-heading text-3xl font-bold text-ink">Nguyên liệu</h1>
          <p className="mt-1 text-sm text-subtle">
            Danh mục nguyên liệu và dinh dưỡng trên 100g, dùng để người dùng soạn công thức và tính kcal.
          </p>
        </div>
        <Button type="button" onClick={() => setFormTarget({ mode: "create" })}>
          <Plus className="size-4" />
          Thêm nguyên liệu
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-3 rounded-3xl border border-border bg-card p-4 shadow-sm">
        <div className="relative min-w-52 flex-1">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-subtle" />
          <input
            type="search"
            value={text}
            onChange={handleSearch}
            placeholder="Tìm theo tên nguyên liệu..."
            aria-label="Tìm nguyên liệu"
            className="h-10 w-full rounded-full border border-border bg-surface pl-10 pr-4 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15"
          />
        </div>
        <SelectField
          aria-label="Lọc thuần chay"
          options={VEGAN_OPTIONS}
          value={vegan}
          onValueChange={handleFilter(setVegan)}
          className="h-10"
        />
        <SelectField
          aria-label="Lọc dị ứng"
          options={ALLERGEN_OPTIONS}
          value={allergen}
          onValueChange={handleFilter(setAllergen)}
          className="h-10"
        />
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : isPending ? (
        <div aria-hidden className="h-64 animate-pulse rounded-3xl border border-border bg-card" />
      ) : items.length === 0 ? (
        <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">
          Không tìm thấy nguyên liệu nào phù hợp.
        </p>
      ) : (
        <div className="overflow-hidden rounded-3xl border border-border bg-card shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] text-left text-sm">
              <thead className="bg-surface text-xs uppercase tracking-wide text-subtle">
                <tr>
                  <th className="px-4 py-3 font-semibold">Nguyên liệu</th>
                  <th className="px-3 py-3 text-right font-semibold">Kcal</th>
                  <th className="px-3 py-3 text-right font-semibold">Đạm</th>
                  <th className="px-3 py-3 text-right font-semibold">Tinh bột</th>
                  <th className="px-3 py-3 text-right font-semibold">Béo</th>
                  <th className="px-3 py-3 text-right font-semibold">Xơ</th>
                  <th className="px-3 py-3 font-semibold">Phân loại</th>
                  <th className="px-3 py-3" />
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {items.map((ingredient) => (
                  <tr key={ingredient.id} className="text-body">
                    <td className="px-4 py-3 font-semibold text-ink">{ingredient.name}</td>
                    <td className="px-3 py-3 text-right tabular-nums">{num(ingredient.caloriesPer100g)}</td>
                    <td className="px-3 py-3 text-right tabular-nums">{num(ingredient.proteinPer100g)}</td>
                    <td className="px-3 py-3 text-right tabular-nums">{num(ingredient.carbsPer100g)}</td>
                    <td className="px-3 py-3 text-right tabular-nums">{num(ingredient.fatPer100g)}</td>
                    <td className="px-3 py-3 text-right tabular-nums">{num(ingredient.fiberPer100g)}</td>
                    <td className="px-3 py-3">
                      <div className="flex flex-wrap gap-1.5">
                        {ingredient.vegan && (
                          <span className="inline-flex items-center gap-1 rounded-full bg-brand-soft px-2 py-0.5 text-[11px] font-medium text-brand">
                            <Leaf className="size-3" />
                            Thuần chay
                          </span>
                        )}
                        {ingredient.allergen && (
                          <span className="inline-flex items-center gap-1 rounded-full bg-warning/15 px-2 py-0.5 text-[11px] font-medium text-warning">
                            <TriangleAlert className="size-3" />
                            Dị ứng
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-3 py-3">
                      <div className="flex justify-end gap-1">
                        <Button
                          type="button"
                          size="icon-sm"
                          variant="ghost"
                          aria-label={`Sửa ${ingredient.name}`}
                          onClick={() => setFormTarget({ mode: "edit", ingredient })}
                        >
                          <Pencil className="size-4" />
                        </Button>
                        <Button
                          type="button"
                          size="icon-sm"
                          variant="ghost"
                          aria-label={`Xóa ${ingredient.name}`}
                          onClick={() => setDeleting(ingredient)}
                        >
                          <Trash2 className="size-4 text-destructive" />
                        </Button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-4 py-3 text-sm text-subtle">
            <span>
              {data.totalElements} nguyên liệu • Trang {data.page + 1}/{Math.max(data.totalPages, 1)}
              {isFetching && " • Đang tải..."}
            </span>
            <div className="flex gap-2">
              <Button
                type="button"
                size="sm"
                variant="outline"
                disabled={data.first || isFetching}
                onClick={() => setPage((p) => Math.max(p - 1, 0))}
              >
                <ChevronLeft className="size-4" />
                Trước
              </Button>
              <Button
                type="button"
                size="sm"
                variant="outline"
                disabled={data.last || isFetching}
                onClick={() => setPage((p) => p + 1)}
              >
                Sau
                <ChevronRight className="size-4" />
              </Button>
            </div>
          </div>
        </div>
      )}

      <p className="text-xs text-subtle">
        Chỉ hiện nguyên liệu đang sử dụng, nguyên liệu đã tắt “Đang sử dụng” sẽ không có trong danh sách này.
      </p>

      <IngredientFormDialog target={formTarget} onClose={() => setFormTarget(null)} />

      <ConfirmDialog
        open={deleting !== null}
        onOpenChange={(open) => !open && setDeleting(null)}
        title="Xóa nguyên liệu?"
        description={`“${deleting?.name ?? ""}” sẽ bị xóa vĩnh viễn. Nếu nguyên liệu đang nằm trong công thức nào đó, hệ thống sẽ không cho xóa.`}
        loading={deleteIngredient.isPending}
        onConfirm={handleDelete}
      />
    </div>
  );
}
