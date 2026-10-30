import { useEffect, useRef, useState } from "react";
import { BadgeCheck, ChevronLeft, ChevronRight, Loader2, Search } from "lucide-react";
import { toast } from "sonner";

import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { useAdminUsers, useUpdateAdminUser } from "@/features/admin/users/hooks/useAdminUsers";
import { useAuthStore } from "@/features/auth/store/authStore";
import { formatDate } from "@/features/payment/utils/paymentFormat";
import SelectField from "@/shared/components/SelectField";

const PAGE_SIZE = 20;
const SEARCH_DEBOUNCE_MS = 400;

const ROLE_OPTIONS = [
  { value: "USER", label: "Người dùng" },
  { value: "ADMIN", label: "Quản trị viên" },
];

const STATUS_OPTIONS = [
  { value: "ACTIVE", label: "Hoạt động" },
  { value: "PENDING", label: "Chờ kích hoạt" },
  { value: "INACTIVE", label: "Ngừng hoạt động" },
  { value: "BLOCKED", label: "Bị khóa" },
];

const ALL = { value: "", label: "" };
const ROLE_FILTER = [{ ...ALL, label: "Mọi vai trò" }, ...ROLE_OPTIONS];
const STATUS_FILTER = [{ ...ALL, label: "Mọi trạng thái" }, ...STATUS_OPTIONS];

const labelOf = (options, value) => options.find((option) => option.value === value)?.label ?? value;

// Trang quản lý người dùng (/admin/users): tìm theo tên / email, lọc vai trò và trạng thái, đổi vai trò / trạng thái.
// Admin không tự khóa hoặc tự hạ quyền mình được (BE trả 1022) nên dòng của chính mình bị khóa thao tác.
export default function AdminUsersScreen() {
  const currentUserId = useAuthStore((s) => s.user?.id);
  const [text, setText] = useState("");
  const [keyword, setKeyword] = useState("");
  const [role, setRole] = useState("");
  const [status, setStatus] = useState("");
  const [page, setPage] = useState(0);
  const [pending, setPending] = useState(null);
  const timerRef = useRef(undefined);

  const { data, isPending, isError, error, isFetching } = useAdminUsers({ keyword, role, status, page, size: PAGE_SIZE });
  const updateUser = useUpdateAdminUser();

  useEffect(() => () => clearTimeout(timerRef.current), []);

  const handleSearch = (event) => {
    const value = event.target.value;
    setText(value);
    clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => {
      setKeyword(value.trim());
      setPage(0);
    }, SEARCH_DEBOUNCE_MS);
  };

  const handleFilter = (setter) => (value) => {
    setter(value);
    setPage(0);
  };

  const confirmChange = async () => {
    try {
      await updateUser.mutateAsync({ id: pending.user.id, field: pending.field, value: pending.value });
      toast.success(pending.field === "status" ? "Đã đổi trạng thái" : "Đã đổi vai trò");
    } catch (err) {
      toast.error(err.message);
    } finally {
      setPending(null);
    }
  };

  const items = data?.content ?? [];
  const pendingOptions = pending?.field === "status" ? STATUS_OPTIONS : ROLE_OPTIONS;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="font-heading text-3xl font-bold text-ink">Người dùng</h1>
        <p className="mt-1 text-sm text-subtle">Tìm kiếm tài khoản, khóa / mở khóa và phân quyền quản trị.</p>
      </div>

      <div className="flex flex-wrap items-center gap-3 rounded-3xl border border-border bg-card p-4 shadow-sm">
        <div className="relative min-w-52 flex-1">
          <Search className="pointer-events-none absolute left-3.5 top-1/2 size-4 -translate-y-1/2 text-subtle" />
          <input
            type="search"
            value={text}
            onChange={handleSearch}
            placeholder="Tìm theo tên hoặc email..."
            aria-label="Tìm người dùng"
            className="h-10 w-full rounded-full border border-border bg-surface pl-10 pr-4 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15"
          />
        </div>
        <SelectField aria-label="Lọc vai trò" options={ROLE_FILTER} value={role} onValueChange={handleFilter(setRole)} className="h-10" />
        <SelectField
          aria-label="Lọc trạng thái"
          options={STATUS_FILTER}
          value={status}
          onValueChange={handleFilter(setStatus)}
          className="h-10"
        />
      </div>

      {isError ? (
        <p className="rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive">{error.message}</p>
      ) : isPending ? (
        <div aria-hidden className="h-64 animate-pulse rounded-3xl border border-border bg-card" />
      ) : items.length === 0 ? (
        <p className="rounded-3xl border border-border bg-card p-6 text-sm text-subtle">Không tìm thấy người dùng nào phù hợp.</p>
      ) : (
        <div className="overflow-hidden rounded-3xl border border-border bg-card shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full min-w-[760px] text-left text-sm">
              <thead className="bg-surface text-xs uppercase tracking-wide text-subtle">
                <tr>
                  <th className="px-4 py-3 font-semibold">Người dùng</th>
                  <th className="px-3 py-3 font-semibold">Ngày tạo</th>
                  <th className="px-3 py-3 font-semibold">Vai trò</th>
                  <th className="px-3 py-3 font-semibold">Trạng thái</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {items.map((user) => {
                  const isSelf = user.id === currentUserId;
                  return (
                    <tr key={user.id} className="text-body">
                      <td className="px-4 py-3">
                        <p className="flex items-center gap-1.5 font-semibold text-ink">
                          {user.fullName || "(Chưa có tên)"}
                          {isSelf && <span className="text-xs font-normal text-subtle">(bạn)</span>}
                        </p>
                        <p className="flex items-center gap-1 text-xs text-subtle">
                          {user.email}
                          {user.emailVerified && <BadgeCheck className="size-3.5 text-brand" aria-label="Email đã xác minh" />}
                        </p>
                      </td>
                      <td className="px-3 py-3 text-xs">{formatDate(user.createdAt)}</td>
                      <td className="px-3 py-3">
                        <SelectField
                          variant="field"
                          aria-label={`Vai trò của ${user.email}`}
                          options={ROLE_OPTIONS}
                          value={user.role}
                          disabled={isSelf}
                          onValueChange={(value) => value !== user.role && setPending({ user, field: "role", value })}
                          className="h-9 w-40"
                        />
                      </td>
                      <td className="px-3 py-3">
                        <SelectField
                          variant="field"
                          aria-label={`Trạng thái của ${user.email}`}
                          options={STATUS_OPTIONS}
                          value={user.status}
                          disabled={isSelf}
                          onValueChange={(value) => value !== user.status && setPending({ user, field: "status", value })}
                          className="h-9 w-44"
                        />
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div className="flex flex-wrap items-center justify-between gap-3 border-t border-border px-4 py-3 text-sm text-subtle">
            <span>
              {data.totalElements} người dùng • Trang {data.page + 1}/{Math.max(data.totalPages, 1)}
              {isFetching && " • Đang tải..."}
            </span>
            <div className="flex gap-2">
              <Button type="button" size="sm" variant="outline" disabled={data.first || isFetching} onClick={() => setPage((p) => Math.max(p - 1, 0))}>
                <ChevronLeft className="size-4" />
                Trước
              </Button>
              <Button type="button" size="sm" variant="outline" disabled={data.last || isFetching} onClick={() => setPage((p) => p + 1)}>
                Sau
                <ChevronRight className="size-4" />
              </Button>
            </div>
          </div>
        </div>
      )}

      <AlertDialog open={pending !== null} onOpenChange={(open) => !open && !updateUser.isPending && setPending(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{pending?.field === "status" ? "Đổi trạng thái tài khoản?" : "Đổi vai trò?"}</AlertDialogTitle>
            <AlertDialogDescription>
              {pending &&
                `${pending.user.fullName || pending.user.email}: ${labelOf(pendingOptions, pending.field === "status" ? pending.user.status : pending.user.role)} → ${labelOf(pendingOptions, pending.value)}.`}
              {pending?.value === "BLOCKED" && " Tài khoản bị khóa sẽ không đăng nhập và không làm mới phiên được nữa."}
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={updateUser.isPending}>Hủy</AlertDialogCancel>
            <AlertDialogAction
              variant={pending?.value === "BLOCKED" ? "destructive" : "default"}
              onClick={confirmChange}
              disabled={updateUser.isPending}
            >
              {updateUser.isPending && <Loader2 className="size-4 animate-spin" />}
              Xác nhận
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
