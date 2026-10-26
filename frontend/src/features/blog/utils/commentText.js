// Giới hạn bình luận khớp CommentRequest của BE: tối đa 500 từ và 5000 ký tự.
export const MAX_COMMENT_WORDS = 500;
export const MAX_COMMENT_CHARS = 5000;

/** Đếm từ giống BE: bỏ khoảng trắng hai đầu rồi tách theo khoảng trắng. */
export function countWords(text) {
  const trimmed = String(text ?? "").trim();
  return trimmed === "" ? 0 : trimmed.split(/\s+/).length;
}
