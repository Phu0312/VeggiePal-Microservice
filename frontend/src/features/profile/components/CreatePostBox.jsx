import { useNavigate } from 'react-router-dom';

import { Button } from '@/components/ui/button';

const DEFAULT_AVATAR =
  'https://ui-avatars.com/api/?name=User&background=10b981&color=fff&size=256';

export default function CreatePostBox({ profile }) {
  const navigate = useNavigate();

  const displayName = profile?.fullName?.trim();
  const avatarUrl = profile?.avatarUrl || DEFAULT_AVATAR;

  const placeholderText = displayName
    ? `${displayName} ơi, hôm nay bạn có công thức nào muốn chia sẻ? 🥬`
    : 'Hôm nay bạn có công thức nào muốn chia sẻ?';

  return (
    <div className="bg-card rounded-3xl p-5 shadow-sm border border-border mb-5">
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 rounded-full overflow-hidden bg-surface shrink-0">
          <img
            src={avatarUrl}
            alt={displayName || 'User'}
            className="w-full h-full object-cover"
            onError={(e) => {
              e.currentTarget.src = DEFAULT_AVATAR;
            }}
          />
        </div>
        <input
          type="text"
          readOnly
          onClick={() => navigate('/recipes/new')}
          placeholder={placeholderText}
          className="flex-1 bg-surface border border-border rounded-full px-4 py-2.5 text-xs text-body focus:outline-none focus:border-brand cursor-pointer placeholder:text-subtle"
        />

        {/* Nút Chia sẻ nội dung -> điều hướng /my-content */}
        <Button
          type="button"
          variant="default"
          size="sm"
          onClick={() => navigate('/my-content')}
          className="shrink-0 rounded-full text-xs font-semibold shadow-xs cursor-pointer px-5"
        >
          Chia sẻ nội dung
        </Button>
      </div>
    </div>
  );
}
