import { MessageCircleHeart } from "lucide-react";
import { Link } from "react-router-dom";

import { buttonVariants } from "@/components/ui/variants/button-variants";

// Thẻ dẫn sang trợ lý AI (/chatbot). Chatbot không nhận câu hỏi qua URL nên đây chỉ là liên kết.
export default function AskBroccoliCard() {
  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <div className="flex items-center gap-3">
        <span className="grid size-10 shrink-0 place-items-center rounded-full bg-brand-soft text-brand">
          <MessageCircleHeart className="size-5" />
        </span>
        <div>
          <h2 className="font-heading text-base font-bold text-ink">Hỏi VeggiePal AI</h2>
          <p className="text-xs text-subtle">Trợ lý dinh dưỡng thuần chay</p>
        </div>
      </div>

      <p className="mt-3 text-xs leading-relaxed text-body">
        Bạn muốn biết món chay nào hợp với mục tiêu dinh dưỡng của mình? Hãy trò chuyện với
        VeggiePal nhé!
      </p>

      <Link to="/chatbot" className={`${buttonVariants({ variant: "default", size: "md" })} mt-3 w-full`}>
        <MessageCircleHeart className="size-4" />
        Trò chuyện ngay
      </Link>
    </section>
  );
}
