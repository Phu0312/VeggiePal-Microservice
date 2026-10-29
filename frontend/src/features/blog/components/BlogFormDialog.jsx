import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { useAuthStore } from "@/features/auth/store/authStore";
import BlogForm from "@/features/blog/components/BlogForm";
import { useCategories } from "@/features/blog/hooks/useCategories";
import { useBlog } from "@/features/blog/hooks/useBlogs";
import { flattenCategories } from "@/features/blog/utils/feedFilters";

// Popup viết bài mới (không có blogId) và sửa bài (có blogId), cần đăng nhập.
// Chế độ sửa nạp bài qua GET /blogs/:id: kèm token thì chủ bài / ADMIN đọc được cả bản nháp, chờ duyệt,
// bị từ chối. Bài bị gỡ (BANNED) không sửa được vì BE từ chối.
export default function BlogFormDialog({ blogId, onClose }) {
  const isEdit = blogId !== undefined;
  const id = Number.isInteger(blogId) && blogId > 0 ? blogId : null;

  const user = useAuthStore((s) => s.user);
  const { data: categoryTree, isPending: categoriesPending, isError: categoriesError } =
    useCategories();
  const { data: blog, isPending: blogPending, isError: blogError } = useBlog(isEdit ? id : null);

  const canEdit = blog && (blog.authorId === user?.id || user?.role === "ADMIN");

  let body;
  if (isEdit && (id === null || blogError)) {
    body = (
      <Notice title="Không mở được bài viết này để sửa" onClose={onClose}>
        Bài viết không tồn tại hoặc bạn không có quyền xem. Nếu bài của bạn, hãy đăng nhập lại rồi thử lại.
      </Notice>
    );
  } else if (isEdit && !blogPending && !canEdit) {
    body = (
      <Notice title="Bạn không có quyền sửa bài viết này" onClose={onClose}>
        Chỉ tác giả hoặc quản trị viên mới sửa được bài viết.
      </Notice>
    );
  } else if (isEdit && blog?.status === "BANNED") {
    body = (
      <Notice title="Bài viết này đã bị gỡ" onClose={onClose}>
        Quản trị viên đã gỡ bài viết nên không thể chỉnh sửa.
      </Notice>
    );
  } else if (categoriesError) {
    body = (
      <Notice title="Không tải được danh mục" onClose={onClose}>
        Vui lòng thử lại sau.
      </Notice>
    );
  } else if (categoriesPending || (isEdit && blogPending)) {
    // Form chỉ dựng sau khi có danh mục + bài, vì dropdown danh mục cần đủ option để hiện giá trị ban đầu.
    body = <FormSkeleton />;
  } else {
    body = (
      <BlogForm
        blog={isEdit ? blog : undefined}
        categories={flattenCategories(categoryTree)}
        onClose={onClose}
      />
    );
  }

  return (
    <Dialog open onOpenChange={(open) => !open && onClose()}>
      <DialogContent className="max-w-3xl bg-surface">
        <DialogHeader>
          <DialogTitle>{isEdit ? "Chỉnh sửa bài viết" : "Viết bài mới"}</DialogTitle>
          <DialogDescription>
            {isEdit
              ? "Cập nhật nội dung bài viết của bạn."
              : "Chia sẻ kiến thức và trải nghiệm ăn chay với cộng đồng."}
          </DialogDescription>
        </DialogHeader>
        {body}
      </DialogContent>
    </Dialog>
  );
}

function Notice({ title, children, onClose }) {
  return (
    <div className="rounded-3xl border border-border bg-card p-8 text-center">
      <h2 className="font-heading text-xl font-bold text-ink">{title}</h2>
      <p className="mt-2 text-sm text-subtle">{children}</p>
      <Button type="button" className="mt-4" onClick={onClose}>
        Đóng
      </Button>
    </div>
  );
}

function FormSkeleton() {
  return (
    <div aria-hidden className="animate-pulse space-y-5 rounded-3xl border border-border bg-card p-5 sm:p-6">
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="h-11 w-full rounded-xl bg-surface" />
      <div className="aspect-[16/6] w-full rounded-2xl bg-surface" />
      <div className="h-56 w-full rounded-xl bg-surface" />
    </div>
  );
}
