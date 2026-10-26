// Bộ lọc của feed blog được lưu trên URL (?q=&sort=&category=) để bấm vào bài rồi
// quay lại vẫn giữ nguyên bộ lọc, và có thể chia sẻ link đã lọc.

// value gửi lên BE (GET /blogs?sort=); "" = mặc định của BE (mới đăng nhất).
export const SORT_OPTIONS = [
  { value: "", label: "Mới nhất" },
  { value: "popular", label: "Nổi bật" },
  { value: "mostViewed", label: "Xem nhiều" },
];

const VALID_SORTS = new Set(SORT_OPTIONS.map((o) => o.value));

/** URLSearchParams -> { keyword, sort, categoryId }; giá trị lạ trên URL bị bỏ qua. */
export function parseFeedFilters(searchParams) {
  const sort = searchParams.get("sort") ?? "";
  const category = searchParams.get("category") ?? "";

  return {
    keyword: (searchParams.get("q") ?? "").trim(),
    sort: VALID_SORTS.has(sort) ? sort : "",
    categoryId: /^[1-9]\d*$/.test(category) ? Number(category) : undefined,
  };
}

/** { keyword, sort, categoryId } -> URLSearchParams, bỏ các giá trị mặc định/rỗng. */
export function toFeedSearchParams({ keyword, sort, categoryId }) {
  const params = new URLSearchParams();
  const trimmed = (keyword ?? "").trim();
  if (trimmed) params.set("q", trimmed);
  if (sort && VALID_SORTS.has(sort)) params.set("sort", sort);
  if (categoryId) params.set("category", String(categoryId));
  return params;
}

/** Có đang lọc/tìm kiếm không (để hiện nút "Xóa bộ lọc" và thông báo rỗng phù hợp). */
export function hasActiveFilters({ keyword, sort, categoryId }) {
  return Boolean(keyword || sort || categoryId);
}

/**
 * Cây danh mục 2 cấp -> danh sách phẳng để làm chip lọc: cha rồi tới con của nó.
 * BE lọc theo đúng categoryId (không gồm danh mục con) nên mỗi cấp là một chip riêng.
 */
export function flattenCategories(tree) {
  return (tree ?? []).flatMap((parent) => [
    { id: parent.id, name: parent.name },
    ...(parent.children ?? []).map((child) => ({ id: child.id, name: child.name })),
  ]);
}
