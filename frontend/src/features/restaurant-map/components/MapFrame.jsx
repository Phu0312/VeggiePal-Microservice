// Khung bo tròn của bản đồ, dùng chung cho bản đồ thật và khung chờ khi đang tải Mapbox.
export default function MapFrame({ children }) {
  return (
    <section className="relative h-[420px] overflow-hidden rounded-3xl border border-border bg-[#EAF3EA] dark:bg-[#0f1e16] sm:h-[520px] lg:sticky lg:top-28 lg:h-[calc(100vh-160px)]">
      {children}
    </section>
  );
}
