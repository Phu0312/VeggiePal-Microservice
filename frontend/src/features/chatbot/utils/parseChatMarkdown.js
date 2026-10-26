/**
 * Phân tích markdown đơn giản mà AI trả về thành cấu trúc block để UI render
 * (không dùng thư viện markdown vì quy ước dự án không thêm dependency).
 * Hỗ trợ: tiêu đề (#), bảng (| a | b |), danh sách (-, *, •, 1.), đường kẻ (---),
 * đoạn văn; inline: **đậm**, *nghiêng*, `code`.
 */

const TABLE_ROW = /^\s*\|.*\|\s*$/;
const TABLE_SEPARATOR = /^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$/;
const HEADING = /^\s{0,3}(#{1,6})\s+(.*)$/;
const BULLET = /^\s*[-*•]\s+(.*)$/;
const ORDERED = /^\s*(\d+)[.)]\s+(.*)$/;
const RULE = /^\s*([-*_])(\s*\1){2,}\s*$/;

function splitRow(line) {
  return line
    .trim()
    .replace(/^\|/, "")
    .replace(/\|$/, "")
    .split("|")
    .map((cell) => cell.trim());
}

/** Tách inline thành các token { type: "text" | "bold" | "italic" | "code" | "br", text }. */
export function parseInline(text) {
  const tokens = [];
  const pattern = /(\*\*[^*]+?\*\*|`[^`]+?`|\*[^*\s][^*]*?\*|<br\s*\/?>)/gi;
  let last = 0;
  let match;
  while ((match = pattern.exec(text)) !== null) {
    if (match.index > last) {
      tokens.push({ type: "text", text: text.slice(last, match.index) });
    }
    const raw = match[0];
    if (/^<br/i.test(raw)) tokens.push({ type: "br", text: "" });
    else if (raw.startsWith("**")) tokens.push({ type: "bold", text: raw.slice(2, -2) });
    else if (raw.startsWith("`")) tokens.push({ type: "code", text: raw.slice(1, -1) });
    else tokens.push({ type: "italic", text: raw.slice(1, -1) });
    last = match.index + raw.length;
  }
  if (last < text.length) tokens.push({ type: "text", text: text.slice(last) });
  return tokens;
}

/** Trả về mảng block: heading | paragraph | list | table | rule. */
export function parseChatMarkdown(content) {
  const lines = String(content ?? "").replace(/\r\n?/g, "\n").split("\n");
  const blocks = [];
  let i = 0;

  while (i < lines.length) {
    const line = lines[i];

    if (!line.trim()) {
      i += 1;
      continue;
    }

    // Bảng: dòng tiêu đề + dòng phân cách (---) + các dòng dữ liệu.
    if (TABLE_ROW.test(line) && i + 1 < lines.length && TABLE_SEPARATOR.test(lines[i + 1]) && lines[i + 1].includes("-")) {
      const header = splitRow(line);
      i += 2;
      const rows = [];
      while (i < lines.length && TABLE_ROW.test(lines[i])) {
        rows.push(splitRow(lines[i]));
        i += 1;
      }
      blocks.push({ type: "table", header, rows });
      continue;
    }

    if (RULE.test(line)) {
      blocks.push({ type: "rule" });
      i += 1;
      continue;
    }

    const heading = line.match(HEADING);
    if (heading) {
      blocks.push({ type: "heading", level: heading[1].length, text: heading[2].trim() });
      i += 1;
      continue;
    }

    if (BULLET.test(line) || ORDERED.test(line)) {
      const ordered = ORDERED.test(line) && !BULLET.test(line);
      const items = [];
      while (i < lines.length) {
        const m = ordered ? lines[i].match(ORDERED) : lines[i].match(BULLET);
        if (!m) break;
        items.push((ordered ? m[2] : m[1]).trim());
        i += 1;
      }
      blocks.push({ type: "list", ordered, items });
      continue;
    }

    // Đoạn văn: gom các dòng liên tiếp không thuộc block khác.
    const para = [line.trim()];
    i += 1;
    while (
      i < lines.length &&
      lines[i].trim() &&
      !TABLE_ROW.test(lines[i]) &&
      !HEADING.test(lines[i]) &&
      !BULLET.test(lines[i]) &&
      !ORDERED.test(lines[i]) &&
      !RULE.test(lines[i])
    ) {
      para.push(lines[i].trim());
      i += 1;
    }
    blocks.push({ type: "paragraph", text: para.join("\n") });
  }

  return blocks;
}
