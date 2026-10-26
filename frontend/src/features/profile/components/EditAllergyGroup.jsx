import { useState } from "react";
import { ChevronDown, ChevronUp, Wheat, Ban } from "lucide-react";

import {
  ALLERGY_CATEGORY_META,
  OTHER_CATEGORY_META,
} from "@/features/profile/utils/editProfileConstants";

/** Một nhóm dị ứng (accordion) với các chip chọn theo allergenId. */
export default function EditAllergyGroup({ category, items, selectedIds, onToggle }) {
  const meta = ALLERGY_CATEGORY_META[category] || OTHER_CATEGORY_META;
  const [isOpen, setIsOpen] = useState(false);
  const selectedCount = items.filter((item) => selectedIds.has(item.id)).length;

  return (
    <div className="rounded-2xl border border-border bg-surface/40 overflow-hidden transition-all">
      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        className="flex w-full items-center justify-between p-3.5 text-left hover:bg-surface transition-colors cursor-pointer"
      >
        <div className="flex items-center gap-2">
          <Wheat className="h-4 w-4 text-warning" />
          <span className="text-xs font-bold text-ink">{meta.name}</span>
          {selectedCount > 0 ? (
            <span className="rounded-full bg-rose-50 dark:bg-rose-950/60 px-2 py-0.5 text-[10px] font-bold text-rose-600 dark:text-rose-400 border border-rose-100 dark:border-rose-900">
              {selectedCount} đã chọn
            </span>
          ) : (
            <span className="rounded-full bg-surface px-2 py-0.5 text-[10px] text-subtle">
              Chưa chọn
            </span>
          )}
        </div>
        {isOpen ? (
          <ChevronUp className="h-4 w-4 text-subtle" />
        ) : (
          <ChevronDown className="h-4 w-4 text-subtle" />
        )}
      </button>

      {isOpen && (
        <div className="p-3.5 pt-1 border-t border-border bg-card">
          <p className="text-[11px] text-subtle mb-2.5">{meta.note}</p>
          <div className="flex flex-wrap gap-2">
            {items.map((item) => {
              const isSelected = selectedIds.has(item.id);
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => onToggle(item.id)}
                  aria-pressed={isSelected}
                  className={`flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-medium transition-all cursor-pointer ${
                    isSelected
                      ? "bg-rose-50 dark:bg-rose-950/60 text-rose-700 dark:text-rose-300 border border-rose-200 dark:border-rose-800 shadow-2xs"
                      : "bg-surface text-body hover:bg-border/60 border border-transparent"
                  }`}
                >
                  {isSelected && <Ban className="size-3.5" />}
                  <span>{item.name}</span>
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
