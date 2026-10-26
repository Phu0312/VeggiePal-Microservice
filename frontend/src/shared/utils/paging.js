/**
 * Trang kế tiếp cho useInfiniteQuery, dựa trên PageResponse của BE ({ page, totalPages }).
 * Trả undefined khi đã hết trang (React Query hiểu là không còn trang sau).
 */
export function getNextPageNumber(lastPage) {
  if (!lastPage) return undefined;
  return lastPage.page + 1 < lastPage.totalPages ? lastPage.page + 1 : undefined;
}

/**
 * Gộp danh sách của mọi trang useInfiniteQuery thành một mảng phẳng.
 * `key` là tên field chứa danh sách: blog-service dùng "items", recipe-service dùng "content".
 */
export function flattenPages(data, key = "items") {
  return (data?.pages ?? []).flatMap((page) => page[key] ?? []);
}
