import { useEffect, useRef, useState } from "react";
import { Leaf, Loader2, Plus, Search } from "lucide-react";

import { useIngredients } from "@/features/ingredient/hooks/useIngredients";

const SEARCH_DEBOUNCE_MS = 300;
const RESULT_SIZE = 8;

/**
 * Ô tìm và thêm nguyên liệu (GET /ingredients?keyword=). Bấm một kết quả để thêm vào công thức.
 * - selectedIds: id đã thêm, bị ẩn khỏi kết quả vì BE không cho trùng nguyên liệu trong 1 công thức
 * - onPick(ingredient): nhận Ingredient đầy đủ (id, name, caloriesPer100g...)
 * Mỗi kết quả kèm `description` của nguyên liệu (nếu có) vì BE ghi ở đó nguyên liệu đang ở trạng thái nào
 * (vd "Gạo thơm" là gạo sống 365 kcal/100g, "Cơm trắng" là cơm đã nấu 130 kcal/100g).
 */
export default function IngredientPicker({ selectedIds, onPick }) {
  const [text, setText] = useState("");
  const [keyword, setKeyword] = useState("");
  const timerRef = useRef(undefined);

  useEffect(() => () => clearTimeout(timerRef.current), []);

  // Lấy dư kết quả để vẫn còn đủ sau khi ẩn các nguyên liệu đã chọn.
  const { data, isPending, isError, error } = useIngredients({
    keyword,
    size: RESULT_SIZE + selectedIds.length,
  });

  const handleChange = (event) => {
    const value = event.target.value;
    setText(value);
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => setKeyword(value.trim()), SEARCH_DEBOUNCE_MS);
  };

  const selected = new Set(selectedIds);
  const results = (data?.content ?? []).filter((i) => !selected.has(i.id)).slice(0, RESULT_SIZE);

  return (
    <div>
      <div className="relative">
        <Search className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-subtle" />
        <input
          type="search"
          value={text}
          onChange={handleChange}
          placeholder="Tìm nguyên liệu để thêm (vd: đậu hũ, nấm hương...)"
          aria-label="Tìm nguyên liệu"
          className="h-11 w-full rounded-xl border border-border bg-surface pl-10 pr-4 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 [&::-webkit-search-cancel-button]:hidden"
        />
      </div>

      <div className="mt-2 overflow-hidden rounded-xl border border-border bg-card">
        {isError ? (
          <p className="px-3 py-2.5 text-sm text-destructive">{error.message}</p>
        ) : isPending ? (
          <p className="flex items-center gap-2 px-3 py-2.5 text-sm text-subtle">
            <Loader2 className="size-4 animate-spin" />
            Đang tìm nguyên liệu...
          </p>
        ) : results.length === 0 ? (
          <p className="px-3 py-2.5 text-sm text-subtle">
            {keyword ? "Không tìm thấy nguyên liệu phù hợp." : "Không còn nguyên liệu nào để thêm."}
          </p>
        ) : (
          <ul className="max-h-64 divide-y divide-border overflow-y-auto">
            {results.map((ingredient) => (
              <li key={ingredient.id}>
                <button
                  type="button"
                  onClick={() => onPick(ingredient)}
                  className="flex w-full items-center gap-3 px-3 py-2.5 text-left transition hover:bg-surface"
                >
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-medium text-ink">{ingredient.name}</span>
                    <span className="block text-xs text-subtle">
                      {Number(ingredient.caloriesPer100g)} kcal • {Number(ingredient.proteinPer100g)}g đạm / 100g
                    </span>
                    {/* description ghi trạng thái nguyên liệu (sống / chín / khô / tươi): chọn nhầm thì calo lệch nhiều lần. */}
                    {ingredient.description && (
                      <span className="mt-0.5 block line-clamp-2 text-xs text-subtle/80">{ingredient.description}</span>
                    )}
                  </span>
                  {ingredient.vegan && (
                    <span className="flex shrink-0 items-center gap-1 rounded-full bg-brand-soft px-2 py-0.5 text-[11px] font-medium text-brand">
                      <Leaf className="size-3" />
                      Thuần chay
                    </span>
                  )}
                  <Plus className="size-4 shrink-0 text-brand" />
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
