import { Loader2, AlertTriangle } from "lucide-react";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogMedia,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

export default function PlanConfirmDialog({
  open,
  onOpenChange,
  onConfirm,
  currentPlan,
  targetPlan,
  loading = false,
}) {
  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogMedia className="bg-amber-500/10 text-amber-600 dark:text-amber-400">
            <AlertTriangle className="size-6" />
          </AlertDialogMedia>
          <AlertDialogTitle>Xác nhận thay đổi gói thành viên</AlertDialogTitle>
          <AlertDialogDescription className="space-y-2 text-sm text-body">
            <span>
              Bạn hiện đang có gói{" "}
              <strong className="text-ink font-semibold">{currentPlan}</strong>.
              Khi chuyển sang gói{" "}
              <strong className="text-ink font-semibold">{targetPlan}</strong>,
              hệ thống sẽ áp dụng gói mới ngay lập tức và thời gian sử dụng còn lại
              của gói cũ sẽ bị hủy (không được cộng dồn hay hoàn tiền).
            </span>
            <span className="block text-subtle text-xs mt-1">
              (Lưu ý: Nếu gia hạn cùng gói đang sử dụng, bạn sẽ được cộng thêm 30 ngày vào hạn dùng hiện tại).
            </span>
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={loading}>Để sau</AlertDialogCancel>
          <AlertDialogAction onClick={onConfirm} disabled={loading} className="gap-2">
            {loading && <Loader2 className="size-4 animate-spin" />}
            Tiếp tục thanh toán
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
