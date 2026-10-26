import { ChevronDown, ChevronUp, Loader2, Save, User } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  accordionBodyClass,
  accordionHeaderClass,
  cardClass,
  errorBoxClass,
  errorTextClass,
  iconBoxClass,
  inputClass,
  labelClass,
  successBoxClass,
} from "@/features/profile/utils/editProfileConstants";

/** Accordion "Thông tin cá nhân" (họ tên, số điện thoại) — nhận form từ usePersonalInfoForm. */
export default function EditPersonalInfoCard({ personal }) {
  const { form, profile, updateProfile, open, toggleOpen, saving, profileLoading } = personal;
  const { errors, isDirty } = form.formState;

  return (
    <div className={`${cardClass} overflow-hidden transition-all`}>
      <button type="button" onClick={toggleOpen} className={accordionHeaderClass}>
        <div className="flex items-center gap-3">
          <div className={iconBoxClass}>
            <User className="h-4 w-4" />
          </div>
          <div>
            <h4 className="text-xs sm:text-sm font-bold text-ink">
              Thông tin cá nhân
            </h4>
            <p className="text-[10px] text-subtle">Họ tên, số điện thoại</p>
          </div>
        </div>
        {open ? (
          <ChevronUp className="h-4 w-4 text-subtle" />
        ) : (
          <ChevronDown className="h-4 w-4 text-subtle" />
        )}
      </button>

      {open && (
        <form onSubmit={form.handleSubmit(personal.onSubmit)} className={accordionBodyClass}>
          <div>
            <label htmlFor="edit-fullName" className={labelClass}>
              Họ và tên
            </label>
            <input
              id="edit-fullName"
              type="text"
              autoComplete="name"
              aria-invalid={Boolean(errors.fullName)}
              className={inputClass}
              {...form.register("fullName")}
            />
            {errors.fullName && <span className={errorTextClass}>{errors.fullName.message}</span>}
          </div>

          <div>
            <label htmlFor="edit-phone" className={labelClass}>
              Số điện thoại
            </label>
            <input
              id="edit-phone"
              type="text"
              autoComplete="tel"
              placeholder="Để trống nếu muốn xóa"
              aria-invalid={Boolean(errors.phone)}
              className={inputClass}
              {...form.register("phone")}
            />
            {errors.phone && <span className={errorTextClass}>{errors.phone.message}</span>}
          </div>

          <div>
            <label htmlFor="edit-email" className={labelClass}>
              Email
            </label>
            <input
              id="edit-email"
              type="email"
              value={profile?.email || ""}
              readOnly
              disabled
              className="w-full rounded-2xl border border-border bg-surface/80 px-3.5 py-2.5 text-xs text-subtle cursor-not-allowed"
            />
            <span className="text-[10px] text-subtle mt-1 block">
              Email không thể thay đổi tại đây
            </span>
          </div>

          {errors.root && <p className={errorBoxClass}>{errors.root.message}</p>}
          {updateProfile.isSuccess && !errors.root && !isDirty && (
            <p className={successBoxClass}>Đã cập nhật thông tin cá nhân.</p>
          )}

          <Button
            type="submit"
            variant="default"
            size="sm"
            disabled={saving || profileLoading}
            className="rounded-xl gap-1.5 font-semibold cursor-pointer"
          >
            {saving ? (
              <Loader2 className="h-3.5 w-3.5 animate-spin" />
            ) : (
              <Save className="h-3.5 w-3.5" />
            )}
            {saving ? "Đang lưu…" : "Lưu thay đổi"}
          </Button>
        </form>
      )}
    </div>
  );
}
