// BE (Spring) nhận list id dạng "1,2,3". axios mặc định serialize mảng thành
// "ids[]=1&ids[]=2" nên BE không đọc được -> luôn nối chuỗi thủ công.

/** Chuẩn hóa danh sách id: ép số, bỏ giá trị lỗi/trùng, sắp xếp tăng dần. */
export function normalizeIds(ids) {
  const valid = (ids ?? [])
    .map(Number)
    .filter((id) => Number.isInteger(id) && id > 0);
  return [...new Set(valid)].sort((a, b) => a - b);
}

/** Chia mảng thành các nhóm tối đa `size` phần tử. */
export function chunk(list, size) {
  const chunks = [];
  for (let i = 0; i < list.length; i += size) {
    chunks.push(list.slice(i, i + size));
  }
  return chunks;
}

/** [1, 2, 3] -> "1,2,3" */
export function joinIds(ids) {
  return ids.join(",");
}
