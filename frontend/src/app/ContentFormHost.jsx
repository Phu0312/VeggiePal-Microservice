import BlogFormDialog from "@/features/blog/components/BlogFormDialog";
import RecipeFormDialog from "@/features/recipe/components/RecipeFormDialog";
import VideoFormDialog from "@/features/video/components/VideoFormDialog";
import { useContentFormStore } from "@/shared/store/contentFormStore";

// Dựng popup tạo / sửa bài viết, công thức, video theo contentFormStore. Đặt một lần trong App
// nên mở popup từ trang nào cũng không đổi URL. `key` buộc dựng lại form khi chuyển sang mục khác.
export default function ContentFormHost() {
  const dialog = useContentFormStore((s) => s.dialog);
  const close = useContentFormStore((s) => s.close);

  if (!dialog) return null;

  const key = `${dialog.kind}:${dialog.id ?? "new"}`;
  if (dialog.kind === "blog") return <BlogFormDialog key={key} blogId={dialog.id} onClose={close} />;
  if (dialog.kind === "recipe") return <RecipeFormDialog key={key} recipeId={dialog.id} onClose={close} />;
  if (dialog.kind === "video") {
    return <VideoFormDialog key={key} videoId={dialog.id} initialVideo={dialog.video} onClose={close} />;
  }
  return null;
}
