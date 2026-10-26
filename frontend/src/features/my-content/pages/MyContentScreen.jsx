import { useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { BookOpen, ChefHat, Plus, Sparkles, Video as VideoIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import MyBlogList from "@/features/my-content/components/MyBlogList";
import MyRecipeList from "@/features/my-content/components/MyRecipeList";
import MyVideoJobList from "@/features/my-content/components/MyVideoJobList";
import MyVideoList from "@/features/my-content/components/MyVideoList";
import UploadVideoJobDialog from "@/features/video/components/UploadVideoJobDialog";
import { cn } from "@/lib/utils";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";

const TABS = [
  { id: "blogs", label: "Bài viết", icon: BookOpen },
  { id: "recipes", label: "Công thức", icon: ChefHat },
  { id: "videos", label: "Video", icon: VideoIcon },
  { id: "extractions", label: "Bóc tách", icon: Sparkles },
];

// Trang "Nội dung của tôi" (route /my-content, cần đăng nhập): bài viết (GET /blogs/me),
// công thức (GET /recipes/me) và video (GET /videos/me) của chính mình ở mọi trạng thái,
// kèm nút tạo mới / sửa / gửi duyệt / xóa. Tab "Bóc tách" là lịch sử AI bóc tách công thức từ video
// (GET /ai/videos), nút góc phải mở hộp thoại tải video lên thay vì chuyển trang.
// Tab nằm trên URL (?tab=videos) để form quay về đúng tab.
export default function MyContentScreen() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [uploadOpen, setUploadOpen] = useState(false);
  const currentTab = searchParams.get("tab");
  const tab = TABS.some(({ id }) => id === currentTab) ? currentTab : "blogs";
  const setTab = (id) => setSearchParams(id === "blogs" ? {} : { tab: id }, { replace: true });

  const getCreateLink = () => {
    if (tab === "videos") return { to: "/videos/new", label: "Đăng video" };
    if (tab === "recipes") return { to: "/recipes/new", label: "Tạo công thức" };
    return { to: "/blog/new", label: "Viết bài mới" };
  };
  const createLink = getCreateLink();

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-3xl flex-col gap-6 px-6 py-6">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <div>
            <h1 className="font-heading text-3xl font-bold text-ink">Nội dung của tôi</h1>
            <p className="mt-1 text-sm text-subtle">
              Quản lý bài viết, công thức và video bạn đã tạo, kể cả bản nháp và nội dung đang chờ duyệt, cùng
              lịch sử AI bóc tách công thức từ video.
            </p>
          </div>
          {tab === "extractions" ? (
            <Button type="button" size="md" onClick={() => setUploadOpen(true)}>
              <Sparkles className="size-4" />
              Bóc tách video
            </Button>
          ) : (
            <Link
              to={createLink.to}
              className={buttonVariants({ variant: "default", size: "md" })}
            >
              <Plus className="size-4" />
              {createLink.label}
            </Link>
          )}
        </div>

        <div role="tablist" className="flex items-center gap-2">
          {TABS.map(({ id, label, icon: Icon }) => (
            <button
              key={id}
              type="button"
              role="tab"
              aria-selected={tab === id}
              onClick={() => setTab(id)}
              className={cn(
                "flex items-center gap-1.5 rounded-full px-4 py-2 text-sm font-medium transition",
                tab === id
                  ? "bg-brand text-brand-foreground"
                  : "bg-surface text-subtle hover:text-ink"
              )}
            >
              <Icon className="size-4" />
              {label}
            </button>
          ))}
        </div>

        {tab === "blogs" ? (
          <MyBlogList />
        ) : tab === "recipes" ? (
          <MyRecipeList />
        ) : tab === "videos" ? (
          <MyVideoList />
        ) : (
          <MyVideoJobList />
        )}
      </main>

      <UploadVideoJobDialog open={uploadOpen} onOpenChange={setUploadOpen} />

      <AppFooter />
    </div>
  );
}
