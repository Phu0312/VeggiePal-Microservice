import { Link } from "react-router-dom";
import { Broccoli, PenLine, Sprout, Trophy } from "lucide-react";

import { Button } from "@/components/ui/button";
import { buttonVariants } from "@/components/ui/variants/button-variants";
import GlassBanner, { GlassChip, GlassPanel } from "@/shared/components/GlassBanner";
import { useContentForm } from "@/shared/hooks/useContentForm";

export default function CommunityHero() {
  const { openForm } = useContentForm();

  return (
    <GlassBanner className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
      <div className="min-w-0">
        <GlassChip icon={Sprout}>Không Gian Sống Lành &amp; Kết Nối Đam Mê Thuần Chay</GlassChip>

        <h1 className="mt-3 font-heading text-3xl font-extrabold text-ink sm:text-4xl">
          Cộng Đồng Bếp Xanh <span className="text-gradient-brand">VeggiePal</span>
        </h1>
        <p className="mt-2 max-w-xl text-sm leading-relaxed text-body">
          Nơi các tín đồ thuần chay cùng VeggiePal chia sẻ dinh dưỡng WFPB, biến tấu công thức
          ấm lòng và lan toả lối sống không rác thải.
        </p>
        <Link to="/community" className={buttonVariants({ variant: "outline", size: "sm", className: "mt-4" })}>
          <Trophy className="size-4" />
          Bảng vàng &amp; thử thách 7 ngày
        </Link>
      </div>

      <GlassPanel className="flex shrink-0 flex-col gap-3 lg:max-w-md">
        <div className="flex items-center gap-3">
          <span className="grid size-14 shrink-0 place-items-center rounded-2xl bg-gradient-to-br from-brand to-brand-2 text-white shadow-md">
            <Broccoli className="size-8" strokeWidth={1.6} />
          </span>
          <div className="min-w-0">
            <p className="font-heading text-base font-bold text-ink">Chia sẻ cùng cộng đồng</p>
            <p className="text-xs text-subtle">Bài viết của bạn được AI kiểm duyệt trước khi đăng</p>
          </div>
        </div>

        {/* Mở popup viết bài; khách chưa đăng nhập được đưa sang trang đăng nhập rồi quay lại. */}
        <Button type="button" size="md" className="w-full" onClick={() => openForm("blog")}>
          <PenLine className="size-4" />
          Viết bài chia sẻ
        </Button>
      </GlassPanel>
    </GlassBanner>
  );
}
