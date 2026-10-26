import { Sprout } from "lucide-react";

/** Câu trích dẫn cuối cột trái. */
export default function EditQuoteCard() {
  return (
    <div className="rounded-3xl border border-brand/30 bg-brand-soft p-5 text-xs text-body">
      <div className="flex items-center gap-1.5 font-bold text-brand mb-1.5">
        <Sprout className="size-3.5" />
        <span>VeggiePal</span>
      </div>
      <p className="italic leading-relaxed">
        "Sống chậm lại để cảm nhận, ăn lành sạch để chữa lành, và mỉm cười để yêu thương trọn vẹn mỗi ngày."
      </p>
    </div>
  );
}
