import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { jobSourceLabel } from "@/features/video/utils/videoJob";

/**
 * Xem kết quả bóc tách của một job COMPLETED: tên món, nguyên liệu kèm số lượng, các bước và bản chép lời.
 * `job` rỗng thì đóng; extraction { title, ingredients: [{ name, quantity }], steps: [{ number, instruction }] }.
 */
export default function VideoJobResultDialog({ job, onClose }) {
  const extraction = job?.extraction;

  return (
    <Dialog open={Boolean(job)} onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-2xl">
        {extraction && (
          <>
            <DialogHeader>
              <DialogTitle>{extraction.title}</DialogTitle>
              <DialogDescription>
                {job.sourceVideoId ? `Từ ${jobSourceLabel(job).toLowerCase()}` : `Từ video “${job.filename}”`}
              </DialogDescription>
            </DialogHeader>

            <section>
              <h3 className="text-sm font-bold text-ink">Nguyên liệu</h3>
              <ul className="mt-2 flex flex-col gap-1.5">
                {extraction.ingredients.map((item, index) => (
                  <li
                    key={index}
                    className="flex justify-between gap-3 rounded-xl bg-surface px-3 py-2 text-sm"
                  >
                    <span className="text-ink">{item.name}</span>
                    <span className="shrink-0 text-subtle">{item.quantity}</span>
                  </li>
                ))}
              </ul>
            </section>

            <section>
              <h3 className="text-sm font-bold text-ink">Các bước thực hiện</h3>
              <ol className="mt-2 flex flex-col gap-2.5">
                {extraction.steps.map((step) => (
                  <li key={step.number} className="flex gap-2.5 text-sm leading-relaxed text-body">
                    <span className="shrink-0 font-bold text-ink">Bước {step.number}:</span>
                    <span>{step.instruction}</span>
                  </li>
                ))}
              </ol>
            </section>

            {job.transcript && (
              <details className="rounded-xl border border-border px-3 py-2 text-sm">
                <summary className="cursor-pointer font-semibold text-ink">Lời trong video</summary>
                <p className="mt-2 whitespace-pre-line leading-relaxed text-body">{job.transcript}</p>
              </details>
            )}

            <p className="text-xs text-subtle">
              Kết quả do AI tạo từ lời trong video, bạn nên đối chiếu lại trước khi dùng.
            </p>
          </>
        )}

        <DialogFooter>
          <Button type="button" variant="outline" onClick={onClose}>
            Đóng
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
