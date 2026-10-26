import { useState } from "react";
import { MapPin, Navigation, Phone, Star, Utensils } from "lucide-react";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import {
  buildDirectionsUrl,
  buildTelUrl,
  formatDistance,
  formatRating,
  veganLabel,
} from "@/features/restaurant-map/utils/restaurantFormat";
import { cn } from "@/lib/utils";

// Quán chưa có ảnh (imageUrl null) hoặc link ảnh hỏng thì hiện khung này.
function ImageFallback() {
  return (
    <div className="grid h-full w-full place-items-center bg-brand-soft text-brand">
      <Utensils className="size-8" />
    </div>
  );
}

// Link ảnh của quán lấy từ nhiều trang ngoài nên có thể hỏng bất cứ lúc nào; `onError` đổi sang khung dự phòng.
function RestaurantImage({ src, alt }) {
  const [failed, setFailed] = useState(false);

  if (!src || failed) return <ImageFallback />;

  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      referrerPolicy="no-referrer"
      onError={() => setFailed(true)}
      className="h-full w-full object-cover"
    />
  );
}

export default function RestaurantCard({ restaurant, selected, onSelect }) {
  const {
    id,
    name,
    rating,
    address,
    distanceKm,
    veganOnly,
    imageUrl,
    phoneNumber,
  } = restaurant;
  const telUrl = buildTelUrl(phoneNumber);
  const distance = formatDistance(distanceKm);

  // Bấm vào thẻ (hoặc Enter) để chọn quán; nút bên trong tự xử lý riêng.
  const handleKeyDown = (event) => {
    if (event.target === event.currentTarget && event.key === "Enter") {
      onSelect(id);
    }
  };

  return (
    <article
      id={`restaurant-card-${id}`}
      tabIndex={0}
      aria-current={selected || undefined}
      onClick={() => onSelect(id)}
      onKeyDown={handleKeyDown}
      className={cn(
        "flex cursor-pointer gap-4 rounded-2xl border bg-card p-3 shadow-[0_1px_2px_rgba(16,24,40,0.04)] outline-none transition hover:shadow-md focus-visible:ring-2 focus-visible:ring-brand/30 sm:p-4",
        selected ? "border-brand ring-2 ring-brand/20" : "border-border",
      )}
    >
      <div className="relative h-28 w-28 shrink-0 overflow-hidden rounded-xl sm:h-32 sm:w-32">
        <RestaurantImage src={imageUrl} alt={name} />
        {/* Nền trắng cố định ở cả hai theme nên chữ phải là màu đậm cố định; text-ink sẽ sáng lên ở dark mode và biến mất */}
        <span className="absolute left-2 top-2 flex items-center gap-1 rounded-full bg-white/95 px-2 py-0.5 text-xs font-bold text-[#111c2d] shadow">
          <Star className="h-3 w-3 fill-[#F5B93D] text-[#F5B93D]" />
          {formatRating(rating)}
        </span>
      </div>

      <div className="flex min-w-0 flex-1 flex-col gap-1.5">
        <h3 className="text-base font-bold leading-snug text-ink">{name}</h3>

        <p className="flex items-center gap-1 text-xs text-subtle">
          <MapPin className="h-3.5 w-3.5 shrink-0" />
          <span className="truncate">{address}</span>
          {distance && <span className="shrink-0">• {distance}</span>}
        </p>

        <div className="flex flex-wrap items-center gap-1.5 text-xs">
          <span className="rounded-full bg-brand-soft px-2 py-0.5 font-medium text-brand">
            {veganLabel(veganOnly)}
          </span>
        </div>

        <div className="mt-auto flex items-center gap-2 pt-1">
          {telUrl ? (
            <a
              href={telUrl}
              onClick={(event) => event.stopPropagation()}
              className={buttonVariants({
                variant: "outline",
                className: "flex-1 shrink bg-transparent px-3 text-xs font-semibold",
              })}
            >
              <Phone className="size-3.5" />
              Gọi điện
            </a>
          ) : (
            <Button
              type="button"
              variant="outline"
              disabled
              className="flex-1 shrink bg-transparent px-3 text-xs font-semibold"
            >
              <Phone className="size-3.5" />
              Gọi điện
            </Button>
          )}
          <a
            href={buildDirectionsUrl(restaurant)}
            target="_blank"
            rel="noopener noreferrer"
            onClick={(event) => event.stopPropagation()}
            className={buttonVariants({
              className: "flex-1 shrink px-3 text-xs",
            })}
          >
            <Navigation className="size-3.5" />
            Chỉ đường đi
          </a>
        </div>
      </div>
    </article>
  );
}
