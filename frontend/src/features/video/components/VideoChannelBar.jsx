import { useRef } from "react";

import iconChannels from "@/assets/img/icon_video_page_2.png";
import { videoChannels } from "@/features/video/data/mockVideo";

// Thanh kênh gợi ý phía trên trang video chính.
// BE chưa có endpoint kênh / người sáng tạo riêng, nên các kênh ở đây được đánh dấu là dữ liệu mẫu.
export default function VideoChannelBar() {
  const scrollerRef = useRef(null);

  const handleWheel = (event) => {
    if (event.deltaY === 0) return;
    scrollerRef.current?.scrollBy({ left: event.deltaY });
    event.preventDefault();
  };

  return (
    <div className="flex flex-col gap-2 rounded-3xl border border-border bg-card p-3 shadow-sm">
      <div className="flex items-center justify-between px-1">
        <span className="text-xs font-semibold text-subtle">
          Kênh ẩm thực đề xuất <span className="text-[11px] font-normal text-subtle/80">(Dữ liệu mẫu)</span>
        </span>
      </div>
      <div
        ref={scrollerRef}
        onWheel={handleWheel}
        className="no-scrollbar flex items-center gap-3 overflow-x-auto"
      >
        <img
          src={iconChannels}
          alt=""
          className="sticky left-0 z-10 h-11 w-11 shrink-0 select-none rounded-full bg-white"
          draggable={false}
        />

        {videoChannels.map((channel) => (
          <button
            key={channel.id}
            type="button"
            className="flex shrink-0 items-center gap-2 rounded-full border border-border bg-card py-1.5 pl-1.5 pr-3.5 text-sm font-medium text-ink transition hover:bg-surface"
          >
            <span
              className={`grid size-7 shrink-0 place-items-center rounded-full text-[11px] font-bold text-white ${channel.avatarClass}`}
            >
              {channel.initials}
            </span>
            {channel.label}
          </button>
        ))}
      </div>
    </div>
  );
}
