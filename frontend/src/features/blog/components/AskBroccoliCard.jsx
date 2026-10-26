import { Send, Sparkles } from "lucide-react";
import { useNavigate } from "react-router-dom";

import { Button } from "@/components/ui/button";

export default function AskBroccoliCard() {
  const navigate = useNavigate();

  // Chatbot chưa nhận câu hỏi qua URL nên chỉ chuyển người dùng sang trang chat.
  const handleSubmit = (event) => {
    event.preventDefault();
    navigate("/chatbot");
  };

  return (
    <section className="rounded-3xl border border-border bg-card p-5 shadow-sm">
      <div className="flex items-center gap-3">
        <span className="grid size-10 shrink-0 place-items-center rounded-full bg-chart-4/20 text-chart-4">
          <Sparkles className="size-5" />
        </span>
        <div>
          <h2 className="font-heading text-base font-bold text-ink">Hỏi Bé Bông Cải AI</h2>
          <p className="text-xs text-subtle">Trợ lý dinh dưỡng 24/7</p>
        </div>
      </div>

      <p className="mt-3 text-xs leading-relaxed text-body">
        Bạn có nguyên liệu gì trong tủ lạnh? Nhập tên vào đây, mình sẽ gợi ý món chay chuẩn
        Macro ngay nhé!
      </p>

      <form onSubmit={handleSubmit} className="relative mt-3">
        <input
          type="text"
          name="question"
          autoComplete="off"
          placeholder="Vd: Đậu hũ, nấm rơm, cà chua..."
          className="h-10 w-full rounded-full border border-border bg-surface pl-4 pr-12 text-xs text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15"
        />
        <Button
          type="submit"
          size="icon-sm"
          aria-label="Gửi câu hỏi"
          className="absolute right-1 top-1/2 -translate-y-1/2"
        >
          <Send className="size-4" />
        </Button>
      </form>
    </section>
  );
}
