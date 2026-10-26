import { useLocation } from "react-router-dom";

import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import Reveal from "@/shared/components/Reveal";

import EditProfileHeader from "@/features/profile/components/EditProfileHeader";
import EditAvatarCard from "@/features/profile/components/EditAvatarCard";
import EditPersonalInfoCard from "@/features/profile/components/EditPersonalInfoCard";
import EditPasswordCard from "@/features/profile/components/EditPasswordCard";
import EditQuoteCard from "@/features/profile/components/EditQuoteCard";
import EditHealthCard from "@/features/profile/components/EditHealthCard";
import EditAllergyCard from "@/features/profile/components/EditAllergyCard";
import EditActionBar from "@/features/profile/components/EditActionBar";
import { usePersonalInfoForm } from "@/features/profile/hooks/usePersonalInfoForm";
import { useAllergyDraft } from "@/features/profile/hooks/useAllergyDraft";
import { useEditProfileActions } from "@/features/profile/hooks/useEditProfileActions";
import { readProfileFixState } from "@/features/profile/utils/profileFixState";

export default function EditProfileScreen() {
  // Được chuyển từ trang thực đơn sang vì hồ sơ thiếu thông tin tính calo: thẻ chỉ số sức khỏe (nơi nhập ngày sinh,
  // giới tính, mức vận động) cuộn tới và làm nổi các ô còn thiếu, và lưu / hủy xong thì quay lại nơi đã chuyển đi
  // (xem readProfileFixState).
  const { state } = useLocation();
  const { missingFields, returnTo, returnLabel } = readProfileFixState(state);

  // Form cá nhân + lựa chọn dị ứng nằm ở đây vì nút "Lưu thông tin" cuối trang lưu cả hai.
  const personal = usePersonalInfoForm();
  const allergy = useAllergyDraft();
  const actions = useEditProfileActions({ personal, allergy, returnTo: returnTo ?? undefined });

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 lg:px-8 space-y-6 text-ink">
        <Reveal>
          <EditProfileHeader profile={personal.profile} />
        </Reveal>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* Cột trái (4/12) */}
          <div className="lg:col-span-4 space-y-5">
            <Reveal>
              <EditAvatarCard
                profile={personal.profile}
                loading={personal.profileLoading}
                error={personal.profileError}
              />
            </Reveal>

            <span className="block text-[11px] font-bold tracking-wider text-subtle uppercase ml-2">
              Giới thiệu
            </span>

            <Reveal><EditPersonalInfoCard personal={personal} /></Reveal>
            <Reveal><EditPasswordCard /></Reveal>
            <Reveal><EditQuoteCard /></Reveal>
          </div>

          {/* Cột phải (8/12) */}
          <div className="lg:col-span-8 space-y-6">
            <Reveal>
              <EditHealthCard highlightFields={missingFields} returnTo={returnTo} returnLabel={returnLabel} />
            </Reveal>
            <Reveal><EditAllergyCard allergy={allergy} /></Reveal>
          </div>
        </div>

        <Reveal>
          <EditActionBar
            status={actions.status}
            saving={actions.saving}
            onSave={actions.saveAll}
            onCancel={actions.cancel}
          />
        </Reveal>
      </main>

      <AppFooter />
    </div>
  );
}