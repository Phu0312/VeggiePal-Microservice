import { Search } from "lucide-react";

import { Button } from "@/components/ui/button";

/**
 * Thanh tìm kiếm quán. BE chưa tìm theo tên nên từ khóa lọc ngay trên danh sách đã tải.
 * - keyword / onKeywordChange: ô tìm kiếm (lọc theo tên hoặc địa chỉ)
 */
export default function MapSearchBar({ keyword, onKeywordChange }) {
  const handleSubmit = (event) => {
    event.preventDefault();
    // Danh sách đã lọc theo từng ký tự gõ; nhấn tìm chỉ đóng bàn phím trên điện thoại.
    document.activeElement?.blur();
  };

  return (
    <section className="rounded-3xl border border-border bg-card p-4 shadow-[0_1px_2px_rgba(16,24,40,0.04)] sm:p-5">
      <form
        onSubmit={handleSubmit}
        className="flex flex-col gap-3 lg:flex-row lg:items-center"
      >
        <label className="relative flex flex-1 items-center">
          <Search className="pointer-events-none absolute left-4 h-4 w-4 text-subtle" />
          <input
            type="search"
            value={keyword}
            onChange={(event) => onKeywordChange(event.target.value)}
            placeholder="Tìm theo tên quán hoặc địa chỉ..."
            aria-label="Tìm quán chay"
            className="h-12 w-full rounded-full border border-border bg-surface pl-11 pr-4 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/30 focus:bg-card focus:ring-2 focus:ring-brand/10"
          />
        </label>

        <Button type="submit" size="xl" className="px-6 text-sm">
          <Search className="size-4" />
          Tìm quán ngon
        </Button>
      </form>
    </section>
  );
}
