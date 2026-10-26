import { FileText, ShieldAlert, Heart } from 'lucide-react';

const tabClass = (active) =>
  `flex items-center gap-2 px-5 py-2 rounded-full text-xs md:text-sm font-semibold transition-all cursor-pointer ${
    active
      ? 'bg-brand-soft text-brand shadow-xs'
      : 'text-subtle hover:text-ink'
  }`;

export default function ProfileTabs({ activeTab, setActiveTab }) {

  return (
    <div className="flex items-center justify-center gap-2 mb-8">
      <div className="inline-flex bg-card/90 p-1.5 rounded-full shadow-sm border border-border backdrop-blur-sm">
        <button
          type="button"
          onClick={() => setActiveTab('posts')}
          className={tabClass(activeTab === 'posts')}
        >
          <FileText className="w-4 h-4 text-brand" />
          Bài viết &amp; Video 
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('moderation')}
          className={tabClass(activeTab === 'moderation')}
        >
          <ShieldAlert className="w-4 h-4 text-warning" />
          Trạng thái kiểm duyệt AI
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('favorites')}
          className={tabClass(activeTab === 'favorites')}
        >
          <Heart className="w-4 h-4 text-rose-500" />
          Đánh giá &amp; Yêu thích
        </button>
      </div>
    </div>
  );
}