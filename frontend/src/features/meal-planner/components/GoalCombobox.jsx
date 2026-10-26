import { useEffect, useRef, useState } from "react";
import { Check, ChevronDown } from "lucide-react";

import { cn } from "@/lib/utils";

/**
 * Ô nhập kèm danh sách chọn nhanh: gõ tự do, hoặc bấm mũi tên (hay phím ↓) để chọn một mục có sẵn.
 * Dùng với react-hook-form qua <Controller>: truyền `value`, `onChange(text)`, `onBlur`, `inputRef` (field.ref).
 * `inputProps` được chuyển thẳng cho <input> (id, maxLength, placeholder, aria-invalid...).
 */
export default function GoalCombobox({ value, onChange, onBlur, inputRef, options, className, ...inputProps }) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef(null);
  const localInputRef = useRef(null);

  // Bấm ra ngoài thì đóng danh sách.
  useEffect(() => {
    if (!open) return undefined;
    const handlePointerDown = (event) => {
      if (rootRef.current && !rootRef.current.contains(event.target)) setOpen(false);
    };
    document.addEventListener("mousedown", handlePointerDown);
    return () => document.removeEventListener("mousedown", handlePointerDown);
  }, [open]);

  const setInputNode = (node) => {
    localInputRef.current = node;
    // field.ref của react-hook-form là hàm callback.
    if (typeof inputRef === "function") inputRef(node);
  };

  const pick = (option) => {
    onChange(option);
    setOpen(false);
    localInputRef.current?.focus();
  };

  const handleKeyDown = (event) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      setOpen(true);
    } else if (event.key === "Escape" && open) {
      event.preventDefault();
      setOpen(false);
    }
  };

  return (
    <div ref={rootRef} className="relative">
      <input
        {...inputProps}
        ref={setInputNode}
        type="text"
        role="combobox"
        aria-expanded={open}
        aria-autocomplete="none"
        autoComplete="off"
        value={value}
        onChange={(event) => onChange(event.target.value)}
        onBlur={onBlur}
        onKeyDown={handleKeyDown}
        className={cn(className, "pr-10")}
      />
      <button
        type="button"
        tabIndex={-1}
        aria-label="Chọn mục tiêu có sẵn"
        onClick={() => setOpen((prev) => !prev)}
        className="absolute inset-y-0 right-0 grid w-10 place-items-center rounded-r-xl text-subtle transition hover:text-ink"
      >
        <ChevronDown className={cn("size-4 transition", open && "rotate-180")} />
      </button>

      {open && (
        <ul
          role="listbox"
          className="absolute left-0 right-0 top-full z-20 mt-1 max-h-60 overflow-y-auto rounded-xl border border-border bg-card p-1 shadow-lg"
        >
          {options.map((option) => {
            const selected = option === value;
            return (
              <li key={option} role="option" aria-selected={selected}>
                <button
                  type="button"
                  onClick={() => pick(option)}
                  className={cn(
                    "flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm transition hover:bg-surface",
                    selected ? "font-semibold text-brand" : "text-ink",
                  )}
                >
                  <span className="min-w-0 flex-1">{option}</span>
                  {selected && <Check className="size-4 shrink-0" />}
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
