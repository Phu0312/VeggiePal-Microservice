import { useState } from "react";
import { Copy, Check, Sparkles, UserRound } from "lucide-react";

import ChatMarkdown from "@/features/chatbot/components/ChatMarkdown";
import { cn } from "@/lib/utils";

function ActionButton({ active, onClick, label, icon: Icon }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={label}
      aria-pressed={active}
      className={cn(
        "grid size-7 place-items-center rounded-full text-subtle transition hover:bg-surface hover:text-ink",
        active && "text-brand"
      )}
    >
      <Icon className="h-3.5 w-3.5" />
    </button>
  );
}

export default function ChatMessage({ message }) {
  const isUser = message.role === "user";
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(message.content);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      // Clipboard không khả dụng (vd. context không secure) — bỏ qua an toàn.
    }
  };

  if (isUser) {
    return (
      <div className="flex flex-col items-end gap-1.5">
        <span className="flex items-center gap-1.5 text-xs font-medium text-subtle">
          Bạn
          <span className="grid size-5 place-items-center rounded-full bg-brand-soft text-brand">
            <UserRound className="h-3 w-3" />
          </span>
        </span>
        <div className="max-w-[80%] rounded-2xl rounded-tr-sm bg-brand px-4 py-2.5 text-sm text-brand-foreground">
          {message.content}
        </div>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-start gap-1.5">
      <span className="flex items-center gap-1.5 text-xs font-medium text-subtle">
        <span className="grid size-5 place-items-center rounded-full bg-brand-soft text-brand">
          <Sparkles className="h-3 w-3" />
        </span>
        Trợ lý Dinh dưỡng VeggiePal
      </span>

      <div className="max-w-[92%] min-w-0 rounded-2xl rounded-tl-sm bg-surface px-4 py-3 text-sm text-body sm:max-w-[85%]">
        <ChatMarkdown content={message.content} />
      </div>

      <div className="flex items-center gap-0.5 pl-1">
        <ActionButton
          label="Sao chép"
          icon={copied ? Check : Copy}
          onClick={handleCopy}
        />
      </div>
    </div>
  );
}
