import { useState } from "react";
import { Link, useLocation } from "react-router-dom";
import { ChevronDown, Loader2, Sparkles } from "lucide-react";

import iconAiSummary from "@/assets/img/icon_video_page_1.png";
import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import { useVideoRecipe } from "@/features/video/hooks/useVideoRecipe";
import { cn } from "@/lib/utils";

// Thu gọn: chỉ hiện vài bước đầu; "Hiện thêm" mới mở hết các bước.
const COLLAPSED_STEPS = 2;

const noteClass = "mt-4 text-sm text-subtle";

// Thẻ "Tóm tắt công thức nấu ăn (AI Summary)" ở trang xem video: công thức AI bóc tách từ chính video này
// (GET /ai/videos/by-video/:id, công khai dùng chung cho mọi người nên xem không tốn lượt). Chưa có thì mời bóc tách
// (POST /ai/videos/process-existing, trừ 1 lượt của gói). Nút ở tiêu đề (VideoMetaHeader) dùng chung trạng thái này.
export default function AiSummaryCard({ video }) {
  const location = useLocation();
  const recipe = useVideoRecipe(video);
  const { status, extraction, noQuota } = recipe;

  const upgradeHint = (
    <div className="mt-4 flex flex-col gap-3 rounded-2xl bg-warning/15 px-4 py-3 text-sm text-warning">
      <p>Gói hiện tại của bạn chưa có lượt bóc tách video. Nâng cấp lên gói PLUS hoặc PRO để dùng tính năng này.</p>
      <Link to="/pricing" className={buttonVariants({ variant: "default", size: "sm", className: "self-start" })}>
        Xem các gói thành viên
      </Link>
    </div>
  );

  const runButton = (label) => (
    <Button type="button" size="sm" className="mt-4" onClick={recipe.run}>
      <Sparkles className="size-3.5" />
      {label}
    </Button>
  );

  return (
    <section id="ai-summary-card" className="rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <div className="flex items-center gap-2.5">
        <img src={iconAiSummary} alt="" className="h-9 w-9 shrink-0" />
        <div>
          <h2 className="text-sm font-bold text-ink sm:text-base">Tóm tắt công thức nấu ăn (AI Summary)</h2>
          <span className="text-[11px] font-medium text-subtle">
            AI nghe lời trong video rồi liệt kê nguyên liệu và các bước làm
          </span>
        </div>
      </div>

      {status === "loading" && (
        <div className="mt-4 flex items-center gap-2 text-sm text-subtle">
          <Loader2 className="size-4 animate-spin text-brand" />
          Đang kiểm tra công thức AI…
        </div>
      )}

      {status === "unsupported" && (
        <p className={noteClass}>
          Chưa hỗ trợ bóc tách video YouTube. Tính năng này hiện chỉ dùng cho video được tải lên trực tiếp (.mp4).
        </p>
      )}

      {status === "login" && (
        <div className="mt-4 flex flex-col items-start gap-3">
          <p className="text-sm text-subtle">
            Video này chưa có công thức AI. Đăng nhập để yêu cầu AI bóc tách nguyên liệu và các bước nấu ăn từ video này.
          </p>
          <Link
            to="/login"
            state={{ from: location }}
            className={buttonVariants({ variant: "default", size: "sm", className: "gap-1.5" })}
          >
            <Sparkles className="size-3.5" />
            Đăng nhập để bóc tách
          </Link>
        </div>
      )}

      {status === "error" && (
        <>
          <p className="mt-4 rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">
            {recipe.error || "Không lấy được công thức AI của video"}
          </p>
          <Button type="button" size="sm" variant="outline" className="mt-3" onClick={() => recipe.refetch()}>
            Thử lại
          </Button>
        </>
      )}

      {status === "none" &&
        (noQuota ? (
          upgradeHint
        ) : (
          <>
            <p className={noteClass}>
              Video này chưa có công thức AI. Bóc tách sẽ dùng 1 lượt trong tháng của gói thành viên (lượt được hoàn
              lại nếu không thành công) và kết quả được dùng chung cho mọi người xem video.
            </p>
            {runButton("Bóc tách công thức")}
          </>
        ))}

      {status === "processing" && (
        <div className="mt-4 flex items-start gap-2 text-sm text-subtle">
          <Loader2 className="mt-0.5 size-4 shrink-0 animate-spin text-brand" />
          <p>
            AI đang bóc tách công thức, có thể mất từ vài chục giây đến vài phút. Bạn có thể ở lại trang này, kết quả
            sẽ tự hiện khi xong.
          </p>
        </div>
      )}

      {status === "failed" &&
        (noQuota ? (
          upgradeHint
        ) : (
          <>
            <p className={noteClass}>
              Lần bóc tách trước chưa thành công, có thể do video không nói rõ nguyên liệu kèm số lượng hoặc AI gặp sự
              cố. Lượt đã dùng được hoàn lại, bạn có thể thử lại.
            </p>
            {runButton("Thử lại")}
          </>
        ))}

      {status === "ready" && extraction && <RecipeContent extraction={extraction} />}
    </section>
  );
}

function RecipeContent({ extraction }) {
  const [expanded, setExpanded] = useState(false);

  const steps = extraction.steps ?? [];
  const canToggle = steps.length > COLLAPSED_STEPS;
  const visibleSteps = expanded || !canToggle ? steps : steps.slice(0, COLLAPSED_STEPS);

  return (
    <>
      <h3 className="mt-4 font-heading text-lg font-bold text-ink">{extraction.title}</h3>

      <h4 className="mt-3 text-sm font-bold text-ink">Nguyên liệu</h4>
      <ul className="mt-2 flex flex-col gap-1.5">
        {extraction.ingredients.map((item, index) => (
          <li key={index} className="flex justify-between gap-3 rounded-xl bg-surface px-3 py-2 text-sm">
            <span className="text-ink">{item.name}</span>
            <span className="shrink-0 text-subtle">{item.quantity}</span>
          </li>
        ))}
      </ul>

      <h4 className="mt-4 text-sm font-bold text-ink">Các bước thực hiện</h4>
      <ol className="mt-2 flex flex-col gap-3">
        {visibleSteps.map((step) => (
          <li key={step.number} className="flex gap-2.5 text-sm leading-relaxed text-body">
            <span className="shrink-0 font-bold text-ink">Bước {step.number}:</span>
            <span>{step.instruction}</span>
          </li>
        ))}
      </ol>

      {canToggle && (
        <button
          type="button"
          onClick={() => setExpanded((v) => !v)}
          aria-expanded={expanded}
          className="mt-4 flex items-center gap-1 text-xs font-semibold text-subtle transition hover:text-ink"
        >
          {expanded ? "Ẩn bớt" : `Hiện thêm (${steps.length - COLLAPSED_STEPS} bước)`}
          <ChevronDown className={cn("h-3.5 w-3.5 transition-transform", expanded && "rotate-180")} />
        </button>
      )}

      <p className="mt-4 text-xs text-subtle">
        Kết quả do AI tạo từ lời trong video, bạn nên đối chiếu lại trước khi dùng.
      </p>
    </>
  );
}
