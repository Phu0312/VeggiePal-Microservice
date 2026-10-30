import { useRef } from "react";
import { ImageUp, Loader2 } from "lucide-react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { useChangeRecipeImage, useUploadRecipeImage } from "@/features/recipe/hooks/useRecipeMutations";
import FallbackImage from "@/shared/components/FallbackImage";

const ACCEPTED_TYPES = ["image/jpeg", "image/png", "image/webp"];
const MAX_BYTES = 5 * 1024 * 1024;

/**
 * Tải ảnh công thức từ máy (JPEG / PNG / WEBP, tối đa 5MB).
 * - Tạo mới: POST /recipes/images, nhận URL rồi điền vào ô link ảnh (lưu cùng công thức).
 * - Sửa (`recipeId`): POST /recipes/:id/image, BE đổi ảnh ngay; URL mới cũng được điền vào form để lần lưu sau giữ nguyên.
 */
export default function RecipeImageUpload({ recipeId, imageUrl, onUploaded }) {
  const inputRef = useRef(null);
  const uploadImage = useUploadRecipeImage();
  const changeImage = useChangeRecipeImage();
  const pending = uploadImage.isPending || changeImage.isPending;

  const handleFile = async (event) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    if (!ACCEPTED_TYPES.includes(file.type)) {
      toast.error("Ảnh phải là JPEG, PNG hoặc WEBP");
      return;
    }
    if (file.size > MAX_BYTES) {
      toast.error("Ảnh không được vượt quá 5MB");
      return;
    }
    try {
      if (recipeId) {
        const updated = await changeImage.mutateAsync({ id: recipeId, file });
        onUploaded(updated?.imageUrl ?? "");
        toast.success("Đã đổi ảnh công thức");
      } else {
        onUploaded(await uploadImage.mutateAsync(file));
        toast.success("Đã tải ảnh lên");
      }
    } catch (error) {
      toast.error(error.message);
    }
  };

  return (
    <div className="mt-2 flex items-center gap-3">
      <FallbackImage
        src={imageUrl}
        alt="Ảnh công thức"
        className="size-14 shrink-0 rounded-xl border border-border object-cover"
      />
      <Button type="button" variant="outline" size="sm" onClick={() => inputRef.current?.click()} disabled={pending}>
        {pending ? <Loader2 className="size-4 animate-spin" /> : <ImageUp className="size-4" />}
        {pending ? "Đang tải ảnh..." : "Tải ảnh từ máy"}
      </Button>
      <input
        ref={inputRef}
        type="file"
        accept={ACCEPTED_TYPES.join(",")}
        className="sr-only"
        tabIndex={-1}
        onChange={handleFile}
      />
    </div>
  );
}
