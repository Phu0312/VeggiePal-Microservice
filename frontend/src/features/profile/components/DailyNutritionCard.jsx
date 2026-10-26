// Component hiển thị dinh dưỡng hàng ngày (mock UI)
import { Activity } from 'lucide-react';

export default function DailyNutritionCard() {
  return (
    <div className="bg-card rounded-3xl p-5 shadow-sm border border-border">
      <div className="flex items-center gap-2 mb-4">
        <Activity className="w-4 h-4 text-brand" />
        <h3 className="font-bold text-ink text-sm">Dinh Dưỡng Hôm Nay</h3>
      </div>

      <div className="flex items-center gap-4 mb-4">
        <div className="relative w-20 h-20 flex items-center justify-center shrink-0">
          <svg className="w-full h-full transform -rotate-90" viewBox="0 0 36 36">
            <path
              className="text-border"
              strokeWidth="3.5"
              stroke="currentColor"
              fill="none"
              d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
            />
            <path
              className="text-brand"
              strokeDasharray="78, 100"
              strokeWidth="3.5"
              strokeLinecap="round"
              stroke="currentColor"
              fill="none"
              d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
            />
          </svg>
          <div className="absolute flex flex-col items-center">
            <span className="text-sm font-extrabold text-ink">1,640</span>
            <span className="text-[9px] text-subtle">kcal</span>
          </div>
        </div>

        <div className="text-xs space-y-1">
          <p className="font-semibold text-ink">Mục tiêu: 2,100 kcal</p>
          <p className="text-brand text-[11px]">Còn 460 kcal cho bữa tối</p>
          <p className="text-subtle text-[10px]">Đã cháy 420 kcal vận động</p>
        </div>
      </div>

      <div className="space-y-3 text-xs">
        <div>
          <div className="flex justify-between text-[11px] mb-1">
            <span className="text-body flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-brand"></span>
              Carbs (Tinh bột Phức, Tinh chất)
            </span>
            <span className="font-semibold text-ink">210g / 260g (80%)</span>
          </div>
          <div className="w-full h-1.5 bg-surface rounded-full overflow-hidden">
            <div className="h-full bg-brand rounded-full" style={{ width: '80%' }}></div>
          </div>
        </div>

        <div>
          <div className="flex justify-between text-[11px] mb-1">
            <span className="text-body flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-teal-600 dark:bg-teal-500"></span>
              Protein thuần thực vật (Nutrient)
            </span>
            <span className="font-semibold text-ink">65g / 75g (87%)</span>
          </div>
          <div className="w-full h-1.5 bg-surface rounded-full overflow-hidden">
            <div className="h-full bg-teal-600 dark:bg-teal-500 rounded-full" style={{ width: '87%' }}></div>
          </div>
        </div>

        <div>
          <div className="flex justify-between text-[11px] mb-1">
            <span className="text-body flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-warning"></span>
              Chất béo tốt (Bơ hạt, Hạt chia)
            </span>
            <span className="font-semibold text-ink">46g / 55g (75%)</span>
          </div>
          <div className="w-full h-1.5 bg-surface rounded-full overflow-hidden">
            <div className="h-full bg-warning rounded-full" style={{ width: '75%' }}></div>
          </div>
        </div>
      </div>
    </div>
  );
}