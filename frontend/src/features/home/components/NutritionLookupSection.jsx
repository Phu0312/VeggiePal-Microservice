import {BookOpen, ChefHat, Layers, Scale, ShieldCheck } from "lucide-react";

import { nutritionLookupCards } from "@/features/home/data/homeData";
import Reveal from "@/shared/components/Reveal";

const ICONS = {
  scale: Scale,
  layers: Layers,
  "chef-hat": ChefHat,
  "shield-check": ShieldCheck,
};

const COLOR_CLASSES = {
  blue: { bg: "bg-chart-2/15", text: "text-chart-2" },
  yellow: { bg: "bg-chart-4/15", text: "text-chart-4" },
  green: { bg: "bg-brand-soft", text: "text-brand" },
};

export default function NutritionLookupSection() {
  return (
    <section className="bg-surface px-6 py-16 font-sans md:px-12 lg:px-16">
      <div className="mx-auto max-w-6xl">
        <Reveal className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-brand">
              <BookOpen className="h-3.5 w-3.5" />
              Cơ Sở Dữ Liệu Chuẩn Hóa
            </p>
            <h2 className="mt-2 text-2xl font-bold text-ink sm:text-3xl">
              Tra cứu Dinh dưỡng &amp; Kiến thức Khoa học
            </h2>
            <p className="mt-2 max-w-2xl text-sm text-subtle">
              Số liệu dinh dưỡng 100g có kiểm nghiệm nguồn gốc (USDA/NIN), quy tắc kiêng kỵ và
              phương pháp bảo tồn vi chất.
            </p>
          </div>
        </Reveal>

        <div className="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {nutritionLookupCards.map((card, index) => {
            const Icon = ICONS[card.icon];
            const colors = COLOR_CLASSES[card.color];

            return (
              <Reveal key={card.id} delay={index * 100}>
                <div className="rounded-2xl border border-border bg-card p-6">
                  <span
                    className={`grid size-11 place-items-center rounded-full ${colors.bg} ${colors.text}`}
                  >
                    <Icon className="h-5 w-5" />
                  </span>
                  <h3 className="mt-4 text-base font-semibold text-ink">{card.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-subtle">{card.description}</p>
                </div>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}
