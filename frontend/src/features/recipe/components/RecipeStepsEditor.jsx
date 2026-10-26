import { useState } from "react";
import { ChevronDown, ChevronUp, GripVertical, Plus, Trash2 } from "lucide-react";
import { useFieldArray } from "react-hook-form";

import { Button } from "@/components/ui/button";
import { RECIPE_LIMITS } from "@/features/recipe/schema";
import { cn } from "@/lib/utils";

const fieldClass =
  "w-full resize-y rounded-xl border border-border bg-surface px-3.5 py-2.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20";

/**
 * Danh sách các bước của công thức: thêm, xóa, đổi thứ tự.
 * - Kéo thả bằng số thứ tự bên trái (HTML5 drag & drop; chỉ phần này kéo được để vẫn bôi đen
 *   chữ trong ô nhập bình thường).
 * - Nút lên/xuống là cách đổi thứ tự dự phòng cho bàn phím và điện thoại, vì kéo thả HTML5
 *   không chạy trên màn hình cảm ứng.
 * Số thứ tự hiển thị theo vị trí; khi gửi lên BE, stepNumber cũng lấy theo vị trí
 * (xem formValuesToPayload). `control`, `register`, `errors` lấy từ useForm của RecipeForm.
 */
export default function RecipeStepsEditor({ control, register, errors }) {
  const { fields, append, remove, move } = useFieldArray({ control, name: "steps" });
  const [dragIndex, setDragIndex] = useState(null);
  const [overIndex, setOverIndex] = useState(null);

  const stepsError = errors.steps?.root?.message ?? errors.steps?.message;
  const canReorder = fields.length > 1;

  const endDrag = () => {
    setDragIndex(null);
    setOverIndex(null);
  };

  const handleDrop = (event, targetIndex) => {
    event.preventDefault();
    if (dragIndex !== null && dragIndex !== targetIndex) move(dragIndex, targetIndex);
    endDrag();
  };

  return (
    <section className="flex flex-col gap-5 rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6">
      <div>
        <h2 className="font-heading text-lg font-bold text-ink">Các bước thực hiện</h2>
        {canReorder && (
          <p className="mt-1 text-xs text-subtle">
            Kéo số thứ tự hoặc dùng nút mũi tên để đổi thứ tự các bước.
          </p>
        )}
      </div>

      <ol className="flex flex-col gap-3">
        {fields.map((field, index) => (
          <li
            key={field.id}
            onDragOver={(event) => {
              if (dragIndex === null) return;
              event.preventDefault(); // cho phép thả vào bước này
              if (overIndex !== index) setOverIndex(index);
            }}
            onDrop={(event) => handleDrop(event, index)}
            className={cn(
              "flex gap-2 rounded-2xl p-1 transition",
              dragIndex === index && "opacity-40",
              overIndex === index && dragIndex !== index && "bg-brand-soft ring-2 ring-brand/40"
            )}
          >
            <div className="mt-1.5 flex shrink-0 flex-col items-center gap-1">
              <span
                draggable={canReorder}
                onDragStart={(event) => {
                  setDragIndex(index);
                  event.dataTransfer.effectAllowed = "move";
                  // Hiện cả dòng khi kéo thay vì chỉ riêng số thứ tự.
                  event.dataTransfer.setDragImage(event.currentTarget.closest("li"), 0, 0);
                }}
                onDragEnd={endDrag}
                title={canReorder ? "Kéo để đổi thứ tự" : undefined}
                className={cn(
                  "grid size-7 place-items-center rounded-full bg-brand-soft text-sm font-bold text-brand",
                  canReorder && "cursor-grab active:cursor-grabbing"
                )}
              >
                {index + 1}
              </span>
              {canReorder && <GripVertical className="size-4 text-subtle" aria-hidden />}
            </div>

            <div className="min-w-0 flex-1">
              <textarea
                rows={2}
                placeholder={`Mô tả bước ${index + 1}`}
                aria-label={`Bước ${index + 1}`}
                maxLength={RECIPE_LIMITS.instruction}
                aria-invalid={Boolean(errors.steps?.[index]?.instruction)}
                className={fieldClass}
                {...register(`steps.${index}.instruction`)}
              />
              {errors.steps?.[index]?.instruction && (
                <p className="mt-1.5 text-xs text-destructive">
                  {errors.steps[index].instruction.message}
                </p>
              )}
            </div>

            <div className="mt-0.5 flex shrink-0 flex-col">
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                aria-label={`Chuyển bước ${index + 1} lên trên`}
                disabled={index === 0}
                onClick={() => move(index, index - 1)}
              >
                <ChevronUp className="size-4" />
              </Button>
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                aria-label={`Chuyển bước ${index + 1} xuống dưới`}
                disabled={index === fields.length - 1}
                onClick={() => move(index, index + 1)}
              >
                <ChevronDown className="size-4" />
              </Button>
              <Button
                type="button"
                variant="ghost"
                size="icon-xs"
                aria-label={`Xóa bước ${index + 1}`}
                disabled={fields.length === 1}
                onClick={() => remove(index)}
              >
                <Trash2 className="size-4 text-destructive" />
              </Button>
            </div>
          </li>
        ))}
      </ol>
      {stepsError && <p className="text-xs text-destructive">{stepsError}</p>}

      <Button
        type="button"
        variant="outline"
        size="sm"
        className="self-start"
        onClick={() => append({ instruction: "" })}
      >
        <Plus className="size-4" />
        Thêm bước
      </Button>
    </section>
  );
}
