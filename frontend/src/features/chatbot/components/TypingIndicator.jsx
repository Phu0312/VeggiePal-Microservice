import { Sparkles } from "lucide-react";

export default function TypingIndicator() {
  return (
    <div className="flex flex-col items-start gap-1.5">
      <span className="flex items-center gap-1.5 text-xs font-medium text-subtle">
        <span className="grid size-5 place-items-center rounded-full bg-brand-soft text-brand">
          <Sparkles className="h-3 w-3" />
        </span>
        Trợ lý Dinh dưỡng VeggiePal
      </span>
      <div className="flex items-center gap-1 rounded-2xl rounded-tl-sm bg-surface px-4 py-3.5">
        {[0, 1, 2].map((i) => (
          <span
            key={i}
            className="size-1.5 animate-bounce rounded-full bg-subtle"
            style={{ animationDelay: `${i * 0.15}s` }}
          />
        ))}
      </div>
    </div>
  );
}
