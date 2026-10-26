// Component hiển thị bộ sưu tập yêu thích (mock UI)
import { Bookmark } from 'lucide-react';

export default function FavoritesCard() {
  const collections = [
    { title: 'Súp bí đỏ', img: 'https://images.unsplash.com/photo-1476718406336-bb5a9690ee2a?auto=format&fit=crop&w=200&q=80' },
    { title: 'Salad rau củ', img: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=200&q=80' },
    { title: 'Gỏi cuốn nấm', img: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=200&q=80' },
    { title: 'Canh rong biển', img: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=200&q=80' },
    { title: 'Bánh mì kẹp', img: 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=200&q=80' },
    { title: 'Lẩu nấm thanh đạm', img: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=200&q=80' },
  ];

  return (
    <div className="bg-card rounded-3xl p-5 shadow-sm border border-border">
      <div className="flex items-center justify-between mb-3.5">
        <div className="flex items-center gap-2">
          <Bookmark className="w-4 h-4 text-brand" />
          <h3 className="font-bold text-ink text-sm">Bộ Sưu Tập Yêu Thích</h3>
        </div>
        <button className="text-[11px] font-semibold text-brand hover:underline cursor-pointer">
          Xem tất cả
        </button>
      </div>

      <div className="grid grid-cols-3 gap-2.5">
        {collections.map((item, idx) => (
          <div key={idx} className="group relative rounded-2xl overflow-hidden aspect-square cursor-pointer">
            <img src={item.img} alt={item.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent flex items-end p-1.5">
              <span className="text-[10px] text-white font-medium line-clamp-1">{item.title}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}