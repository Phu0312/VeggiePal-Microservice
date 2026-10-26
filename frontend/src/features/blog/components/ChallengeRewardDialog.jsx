import { useNavigate } from "react-router-dom";
import { Heart, PartyPopper, Ticket } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { CHALLENGE_BADGE_NAME, CHALLENGE_DAYS } from "@/features/blog/utils/challenge";

// Voucher mang tính minh họa: chưa có BE phát mã thật, nên mã và ưu đãi là nội dung cố định.
const VOUCHER_TITLE = "Giảm 20% hóa đơn tại quán chay đối tác";
const VOUCHER_CODE = "TRAITIMXANH";

/** Popup chúc mừng khi hoàn thành thử thách: mở khóa huy hiệu + voucher. */
export default function ChallengeRewardDialog({ open, onOpenChange }) {
  const navigate = useNavigate();

  const goToProfile = () => {
    onOpenChange(false);
    navigate("/profile");
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md text-center">
        <DialogHeader className="items-center gap-2">
          <span className="grid size-16 place-items-center rounded-full bg-brand-soft text-brand">
            <PartyPopper className="size-8" />
          </span>
          <DialogTitle className="text-2xl">Chúc mừng bạn đã hoàn thành!</DialogTitle>
          <DialogDescription>
            {CHALLENGE_DAYS} ngày sống thuần chay liên tiếp, bạn thật sự là một người Sống Xanh. Đây là
            phần thưởng dành cho bạn.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-3 text-left">
          <div className="flex items-center gap-3 rounded-2xl border border-border bg-surface p-3.5">
            <span className="grid size-11 shrink-0 place-items-center rounded-full bg-chart-4/20 text-chart-4">
              <Heart className="size-5 fill-current" />
            </span>
            <div className="min-w-0">
              <p className="text-xs font-medium text-subtle">Huy hiệu độc quyền</p>
              <p className="font-heading text-base font-bold text-ink">{CHALLENGE_BADGE_NAME}</p>
              <p className="text-xs text-body">Hiển thị cạnh tên bạn trên trang cá nhân.</p>
            </div>
          </div>

          <div className="flex items-center gap-3 rounded-2xl border border-dashed border-brand/40 bg-brand-soft p-3.5">
            <span className="grid size-11 shrink-0 place-items-center rounded-full bg-card text-brand">
              <Ticket className="size-5" />
            </span>
            <div className="min-w-0">
              <p className="text-xs font-medium text-subtle">Voucher quán chay đối tác</p>
              <p className="text-sm font-semibold text-ink">{VOUCHER_TITLE}</p>
              <p className="mt-0.5 text-xs text-body">
                Mã: <span className="font-bold tracking-wider text-brand">{VOUCHER_CODE}</span>
              </p>
            </div>
          </div>
        </div>

        <DialogFooter className="justify-center">
          <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
            Đóng
          </Button>
          <Button type="button" onClick={goToProfile}>
            Xem trang cá nhân
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
