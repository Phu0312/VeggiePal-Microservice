import { Sparkles } from "lucide-react";

export default function ChatEmptyState() {
  return (
    <div className="flex flex-col items-center gap-6 py-6 text-center">
      <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-soft px-3.5 py-1.5 text-xs font-semibold text-brand">
        <Sparkles className="h-3.5 w-3.5" />
        Trợ lý Dinh dưỡng VeggiePal
      </span>

      <div className="space-y-2">
        <h2 className="text-2xl font-bold text-ink sm:text-3xl">
          Hôm nay bạn muốn nấu hoặc tìm hiểu món gì?
        </h2>
        <p className="mx-auto max-w-lg text-sm text-subtle">
          Tôi có thể giúp bạn giải đáp về giá trị dinh dưỡng, công thức món
          chay chuẩn Việt và cân đối calo theo thể trạng.
        </p>
      </div>
    </div>
  );
}
