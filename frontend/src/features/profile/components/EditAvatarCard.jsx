import { useRef, useState } from "react";
import { Camera, Loader2, User } from "lucide-react";

import { useUploadAvatar } from "@/features/profile/hooks/useProfile";
import { validateAvatarFile } from "@/features/profile/utils/editProfileHelpers";
import {
  AVATAR_ALLOWED_TYPES,
  cardClass,
  errorBoxClass,
  successBoxClass,
} from "@/features/profile/utils/editProfileConstants";

/** Thẻ đầu cột trái: avatar (có upload), tên và vai trò thật của user. */
export default function EditAvatarCard({ profile, loading, error }) {
  const fileRef = useRef(null);
  const upload = useUploadAvatar();
  const uploading = upload.isPending;
  const [avatarError, setAvatarError] = useState("");

  const displayName =
    profile?.fullName?.trim() || (loading ? "Đang tải…" : "Người dùng VeggiePal");
  const roleText = profile?.role === "ADMIN" ? "Administrator" : "VeggiePal Member";

  const handleFile = async (e) => {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;

    const invalid = validateAvatarFile(file);
    if (invalid) {
      setAvatarError(invalid);
      return;
    }
    setAvatarError("");
    try {
      // onSuccess của mutation đã ghi hồ sơ mới vào cache + authStore.
      await upload.mutateAsync(file);
    } catch (err) {
      setAvatarError(err.message || "Upload ảnh đại diện thất bại");
    }
  };

  const shownError = avatarError || (error && !profile ? error : "");

  return (
    <>
      <div className={`flex items-center gap-3.5 p-4 ${cardClass}`}>
        <div className="relative flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl bg-surface border border-border text-ink font-bold text-xl shadow-xs">
          {profile?.avatarUrl ? (
            <img
              src={profile.avatarUrl}
              alt={displayName}
              className="h-full w-full rounded-2xl object-cover"
            />
          ) : (
            <User className="h-7 w-7 text-brand" />
          )}
          <button
            type="button"
            onClick={() => !uploading && fileRef.current?.click()}
            disabled={uploading}
            aria-label="Đổi ảnh đại diện"
            className="absolute -bottom-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-brand text-brand-foreground shadow hover:bg-brand/90 disabled:opacity-70 cursor-pointer"
          >
            {uploading ? (
              <Loader2 className="h-3 w-3 animate-spin" />
            ) : (
              <Camera className="h-3 w-3" />
            )}
          </button>
          <input
            ref={fileRef}
            type="file"
            accept={AVATAR_ALLOWED_TYPES.join(",")}
            className="hidden"
            onChange={handleFile}
          />
        </div>
        <div className="min-w-0">
          <h3 className="truncate font-bold text-ink text-base">
            {displayName}
          </h3>
          <p className="text-xs text-subtle">{roleText}</p>
        </div>
      </div>
      {shownError && <p className={`mt-2 ${errorBoxClass}`}>{shownError}</p>}
      {upload.isSuccess && !shownError && !uploading && (
        <p className={`mt-2 ${successBoxClass}`}>Đã cập nhật ảnh đại diện.</p>
      )}
    </>
  );
}
