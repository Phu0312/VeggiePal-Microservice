import { parseChatMarkdown, parseInline } from "@/features/chatbot/utils/parseChatMarkdown";
import { cn } from "@/lib/utils";

function Inline({ text }) {
  return parseInline(text).map((token, index) => {
    switch (token.type) {
      case "bold":
        return (
          <strong key={index} className="font-semibold text-ink">
            {token.text}
          </strong>
        );
      case "italic":
        return <em key={index}>{token.text}</em>;
      case "code":
        return (
          <code key={index} className="rounded bg-brand-soft px-1 py-0.5 text-xs text-brand">
            {token.text}
          </code>
        );
      case "br":
        return <br key={index} />;
      default:
        return token.text;
    }
  });
}

const headingClass = {
  1: "text-base font-semibold text-ink",
  2: "text-base font-semibold text-ink",
  3: "text-sm font-semibold text-ink",
};

/**
 * Hiển thị nội dung AI trả về (markdown) thành tiêu đề / bảng / danh sách gọn gàng.
 * Render bằng React element, không dùng dangerouslySetInnerHTML nên an toàn với nội dung AI.
 */
export default function ChatMarkdown({ content }) {
  const blocks = parseChatMarkdown(content);

  return (
    <div className="flex flex-col gap-3 break-words">
      {blocks.map((block, index) => {
        switch (block.type) {
          case "heading":
            return (
              <p key={index} className={headingClass[block.level] ?? headingClass[3]}>
                <Inline text={block.text} />
              </p>
            );
          case "rule":
            return <hr key={index} className="border-border" />;
          case "list": {
            const ListTag = block.ordered ? "ol" : "ul";
            return (
              <ListTag
                key={index}
                className={cn(
                  "flex flex-col gap-1.5 pl-5",
                  block.ordered ? "list-decimal" : "list-disc"
                )}
              >
                {block.items.map((item, itemIndex) => (
                  <li key={itemIndex} className="pl-1 marker:text-brand">
                    <Inline text={item} />
                  </li>
                ))}
              </ListTag>
            );
          }
          case "table":
            return (
              <div
                key={index}
                className="overflow-x-auto rounded-xl border border-border bg-card"
              >
                <table className="w-full min-w-[420px] border-collapse text-left text-xs">
                  <thead className="bg-brand-soft text-brand">
                    <tr>
                      {block.header.map((cell, cellIndex) => (
                        <th key={cellIndex} className="px-3 py-2 font-semibold">
                          <Inline text={cell} />
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <tbody>
                    {block.rows.map((row, rowIndex) => (
                      <tr key={rowIndex} className="border-t border-border align-top">
                        {block.header.map((_, cellIndex) => (
                          <td key={cellIndex} className="px-3 py-2">
                            <Inline text={row[cellIndex] ?? ""} />
                          </td>
                        ))}
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            );
          default:
            return (
              <p key={index} className="whitespace-pre-wrap">
                <Inline text={block.text} />
              </p>
            );
        }
      })}
    </div>
  );
}
