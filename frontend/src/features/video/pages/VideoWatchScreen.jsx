import { Link, useParams } from "react-router-dom";
import { ArrowLeft, PlaySquare } from "lucide-react";

import { buttonVariants } from "@/components/ui/variants/button-variants";
import AiSummaryCard from "@/features/video/components/AiSummaryCard";
import CommentsHeader from "@/features/video/components/CommentsHeader";
import NutritionFactsCard from "@/features/video/components/NutritionFactsCard";
import SuggestedVideoList from "@/features/video/components/SuggestedVideoList";
import VideoMetaHeader from "@/features/video/components/VideoMetaHeader";
import VideoPlayerFrame from "@/features/video/components/VideoPlayerFrame";
import { useVideo } from "@/features/video/hooks/useVideos";
import AppFooter from "@/shared/components/AppFooter";
import AppHeader from "@/shared/components/AppHeader";
import Reveal from "@/shared/components/Reveal";
import { usePublicUsers } from "@/shared/hooks/usePublicUsers";

// Trang xem video chi tiết (route /videos/:videoId, công khai).
// Nạp dữ liệu qua GET /videos/:id (BE tính 1 lượt xem mỗi lần xem).
export default function VideoWatchScreen() {
  const { videoId } = useParams();
  const id = /^[1-9]\d*$/.test(videoId ?? "") ? Number(videoId) : null;

  const { data: video, isPending, isError, error } = useVideo(id);
  const { data: authors } = usePublicUsers(video ? [video.authorId] : []);
  const author = video ? authors?.get(video.authorId) : null;

  if (id === null || (isError && !isPending)) {
    return (
      <div className="min-h-dvh">
        <AppHeader />
        <main className="mx-auto flex w-full max-w-xl flex-col items-center justify-center px-6 py-20 text-center">
          <div className="grid size-16 place-items-center rounded-3xl bg-destructive/10 text-destructive">
            <PlaySquare className="size-8" />
          </div>
          <h1 className="mt-4 font-heading text-2xl font-bold text-ink">
            Không tìm thấy video
          </h1>
          <p className="mt-2 text-sm text-subtle">
            {error?.message ?? "Video này không tồn tại hoặc đã bị gỡ."}
          </p>
          <Link
            to="/videos"
            className={buttonVariants({ variant: "default", size: "md", className: "mt-6" })}
          >
            <ArrowLeft className="size-4" />
            Về danh sách video
          </Link>
        </main>
        <AppFooter />
      </div>
    );
  }

  return (
    <div className="min-h-dvh">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-[1280px] flex-col gap-6 px-6 py-6">
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
          <div className="flex flex-col gap-6 lg:col-span-2">
            <VideoPlayerFrame video={video} />
            <Reveal>
              <VideoMetaHeader video={video} author={author} />
            </Reveal>
            <Reveal>
              <AiSummaryCard video={video} />
            </Reveal>
            <Reveal>
              <CommentsHeader />
            </Reveal>
          </div>

          <div className="flex flex-col gap-6">
            <Reveal>
              <NutritionFactsCard />
            </Reveal>
            <Reveal>
              <SuggestedVideoList
                currentVideoId={id}
                categoryId={video?.categoryId}
              />
            </Reveal>
          </div>
        </div>
      </main>

      <AppFooter />
    </div>
  );
}
