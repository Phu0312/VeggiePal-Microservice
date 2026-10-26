import { Sparkles, Plus, Globe } from "lucide-react";

import { Button } from "@/components/ui/button";

export default function ChatHeader({ title, onNewChat }) {
  return (
    <header className="flex items-center justify-between border-b border-border px-6 py-4">
      <div className="flex min-w-0 items-center gap-2.5">
        <span className="grid size-8 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
          <Sparkles className="h-4.5 w-4.5" />
        </span>
        <h1 className="truncate text-base font-semibold text-ink">{title}</h1>
      </div>

      <div className="flex shrink-0 items-center gap-2">
        <Button type="button" variant="outline" onClick={onNewChat}>
          <Plus className="size-4" />
          Mới
        </Button>
        <Button type="button" variant="outline">
          <Globe className="size-4" />
          Khám phá
        </Button>
      </div>
    </header>
  );
}
