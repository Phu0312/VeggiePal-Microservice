import { Bookmark, Share2 } from "lucide-react";
import { toast } from "sonner";

import { extractYouTubeId } from "@/features/video/utils/videoForm";

/**
 * Trình phát video:
 * - sourceType === "YOUTUBE": dùng <iframe> với videoUrl là embed URL do BE trả về.
 * - sourceType === "UPLOAD": dùng thẻ <video> HTML5 với videoUrl là tệp .mp4.
 */
export default function VideoPlayerFrame({ video }) {
  if (!video) {
    return (
      <div className="relative aspect-video w-full animate-pulse overflow-hidden rounded-3xl bg-surface" />
    );
  }

  const embedUrl = (() => {
    if (video.sourceType !== "YOUTUBE" || !video.videoUrl) return "";
    if (video.videoUrl.includes("/embed/")) return video.videoUrl;
    const yId = extractYouTubeId(video.videoUrl);
    return yId ? `https://www.youtube.com/embed/${yId}?enablejsapi=1` : video.videoUrl;
  })();

  const handleShare = async () => {
    try {
      if (navigator.share) {
        await navigator.share({
          title: video.title,
          url: window.location.href,
        });
      } else {
        await navigator.clipboard.writeText(window.location.href);
        toast.success("Đã sao chép liên kết video vào bộ nhớ tạm");
      }
    } catch {
      // Người dùng hủy chia sẻ
    }
  };

  const handleBookmark = () => {
    toast.info("Tính năng lưu video yêu thích đang được phát triển.");
  };

  return (
    <div className="relative aspect-video w-full overflow-hidden rounded-3xl bg-black shadow-lg">
      {video.sourceType === "YOUTUBE" ? (
        <iframe
          src={embedUrl}
          title={video.title}
          className="size-full border-0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          allowFullScreen
        />
      ) : (
        <video
          src={video.videoUrl}
          poster={video.thumbnailUrl}
          controls
          playsInline
          className="size-full object-contain"
        >
          Trình duyệt của bạn không hỗ trợ thẻ video.
        </video>
      )}

      {/* Nút thao tác nhanh trên góc */}
      <div className="absolute right-4 top-4 flex items-center gap-2 z-10 pointer-events-auto">
        <button
          type="button"
          onClick={handleBookmark}
          aria-label="Lưu video"
          className="grid size-9 place-items-center rounded-full bg-black/60 text-white transition hover:bg-black/80 backdrop-blur-sm"
        >
          <Bookmark className="size-4" />
        </button>
        <button
          type="button"
          onClick={handleShare}
          aria-label="Chia sẻ video"
          className="grid size-9 place-items-center rounded-full bg-black/60 text-white transition hover:bg-black/80 backdrop-blur-sm"
        >
          <Share2 className="size-4" />
        </button>
      </div>
    </div>
  );
}
