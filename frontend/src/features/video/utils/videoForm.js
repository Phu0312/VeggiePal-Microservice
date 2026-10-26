// Tiện ích thuần cho video: kiểm tra định dạng/dung lượng video & diễn giải kết quả kiểm duyệt.

export const VIDEO_MAX_BYTES = 30 * 1024 * 1024; // 30MB
export const VIDEO_TITLE_MAX = 150;
export const VIDEO_DESCRIPTION_MAX = 5000;

const YOUTUBE_HOSTS = new Set(["youtube.com", "www.youtube.com", "m.youtube.com"]);
const VIDEO_ID_REGEX = /^[A-Za-z0-9_-]{11}$/;

/**
 * Trích xuất ID 11 ký tự của video YouTube từ link người dùng nhập.
 * Khớp hoàn toàn với bộ lọc của backend (YouTubeUrls.java).
 * Hỗ trợ: youtu.be/<id>, youtube.com/watch?v=<id>, /embed/<id>, /shorts/<id>.
 */
export function extractYouTubeId(url) {
  if (!url || typeof url !== "string") return null;
  const trimmed = url.trim();

  try {
    const parsed = new URL(trimmed);
    const scheme = parsed.protocol.replace(":", "").toLowerCase();
    if (scheme !== "http" && scheme !== "https") return null;

    const host = parsed.hostname.toLowerCase();
    const pathname = parsed.pathname;

    let candidate = null;
    if (host === "youtu.be") {
      candidate = pathname.startsWith("/") ? pathname.slice(1) : pathname;
    } else if (YOUTUBE_HOSTS.has(host)) {
      if (pathname === "/watch") {
        candidate = parsed.searchParams.get("v");
      } else if (pathname.startsWith("/embed/")) {
        candidate = pathname.slice("/embed/".length);
      } else if (pathname.startsWith("/shorts/")) {
        candidate = pathname.slice("/shorts/".length);
      }
    }

    if (candidate && VIDEO_ID_REGEX.test(candidate)) {
      return candidate;
    }
  } catch {
    return null;
  }

  return null;
}

/**
 * Kiểm tra tệp video: bắt buộc .mp4 và dung lượng ≤ 30MB.
 * Trả về chuỗi lỗi tiếng Việt nếu không hợp lệ, hoặc null nếu hợp lệ.
 */
export function validateVideoFile(file) {
  if (!file) return "Vui lòng chọn tệp video";

  const isMp4 =
    file.type === "video/mp4" || file.name.toLowerCase().endsWith(".mp4");
  if (!isMp4) {
    return "Video phải là tệp định dạng .mp4";
  }

  if (file.size > VIDEO_MAX_BYTES) {
    return "Tệp video vượt quá dung lượng cho phép (tối đa 30MB)";
  }

  return null;
}

/**
 * Diễn giải VideoResponse sau khi tạo / sửa / gửi duyệt thành thông báo toast cho người dùng.
 * Trả { tone: "success" | "info" | "error", message }.
 */
export function describeVideoOutcome(video) {
  switch (video?.status) {
    case "PUBLISHED":
      return { tone: "success", message: "Video đã được đăng" };
    case "PENDING":
      return {
        tone: "info",
        message: "Video đang chờ kiểm duyệt, bạn sẽ thấy nó khi được duyệt",
      };
    case "REJECTED":
      return {
        tone: "error",
        message: video.moderationReason
          ? `Video không vượt qua kiểm duyệt: ${video.moderationReason}`
          : "Video không vượt qua kiểm duyệt",
      };
    case "BANNED":
      return { tone: "error", message: "Video đã bị gỡ bởi quản trị viên" };
    default:
      return { tone: "success", message: "Đã lưu bản nháp video" };
  }
}
