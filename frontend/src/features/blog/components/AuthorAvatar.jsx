import { FALLBACK_AUTHOR_NAME, getInitials } from "@/features/blog/utils/blogFormat";
import { cn } from "@/lib/utils";
import FallbackImage from "@/shared/components/FallbackImage";

// Avatar tác giả: ảnh nếu có, không thì chữ cái đầu của tên trên nền brand nhạt.
// `author` là { fullName, avatarUrl } từ usePublicUsers, có thể undefined.

export default function AuthorAvatar({ author, className = "size-11 text-sm" }) {
  const name = author?.fullName ?? FALLBACK_AUTHOR_NAME;

  return (
    <FallbackImage
      src={author?.avatarUrl}
      alt={name}
      className={cn("shrink-0 rounded-full object-cover", className)}
      draggable={false}
      // Chưa có avatar hoặc ảnh tải lỗi -> chữ cái đầu của tên.
      fallback={
        <span
          className={cn(
            "grid shrink-0 place-items-center rounded-full bg-brand-soft font-bold text-brand",
            className
          )}
        >
          {getInitials(name)}
        </span>
      }
    />
  );
}
