import { Link } from "react-router-dom";
import { Heart, Leaf, ShieldCheck, Star } from "lucide-react";

const EXPLORE_LINKS = [
  { id: "home", label: "Trang chủ", to: "/" },
  { id: "videos", label: "Video", to: "/videos" },
  { id: "restaurants", label: "Nhà hàng chay", to: "/map" },
  { id: "community", label: "Cộng đồng", to: "/blog" },
  { id: "meal-planner", label: "Lên kế hoạch dinh dưỡng", to: "/meal-planner" },
];

const COMMITMENTS = [
  { id: "plant", Icon: Leaf, title: "100% thực vật", desc: "Thân thiện với môi trường" },
  { id: "nutrition", Icon: Heart, title: "Dinh dưỡng khoa học", desc: "Được chuyên gia tư vấn" },
  { id: "community", Icon: ShieldCheck, title: "Cộng đồng tích cực", desc: "Lan tỏa lối sống lành mạnh" },
  { id: "quality", Icon: Star, title: "Chất lượng hàng đầu", desc: "Luôn đặt người dùng lên trước" },
];

function FooterLink({ to, children }) {
  return (
    <Link to={to} className="text-sm leading-tight text-subtle transition hover:text-ink">
      {children}
    </Link>
  );
}

export default function AppFooter() {
  return (
    <footer className="mt-12 bg-background px-6 sm:px-8">
      <div className="mx-auto grid w-full max-w-[1230px] grid-cols-1 gap-x-8 gap-y-8 py-10 sm:grid-cols-2 lg:grid-cols-[minmax(0,1fr)_auto_auto] lg:gap-x-16">
        <div className="flex max-w-md flex-col gap-3 sm:col-span-2 lg:col-span-1">
          <p className="text-xs font-semibold tracking-[0.15em] text-brand">
            ĂN CHAY • SỐNG KHỎE • KẾT NỐI CỘNG ĐỒNG
          </p>
          <p className="text-sm leading-snug text-subtle">
            VeggiePal là nền tảng dinh dưỡng thực vật, nuôi dưỡng sức khỏe và kết
            nối những tâm hồn cùng chung giá trị sống xanh.
          </p>
          <p className="flex items-center gap-1.5 text-sm italic leading-tight text-brand">
            Vì một tương lai xanh hơn <Leaf className="h-4 w-4" />
          </p>
        </div>

        <nav className="flex flex-col gap-2.5 lg:col-span-1">
          <p className="text-sm font-semibold text-ink">Khám phá</p>
          {EXPLORE_LINKS.map((link) => (
            <FooterLink key={link.id} to={link.to}>
              {link.label}
            </FooterLink>
          ))}
        </nav>

        <div className="flex flex-col gap-2.5 sm:col-span-2 lg:col-span-1">
          <p className="text-sm font-semibold text-ink">Cam kết của chúng tôi</p>
          <div className="flex flex-col gap-3">
            {COMMITMENTS.map(({ id, Icon, title, desc }) => (
              <div key={id} className="flex items-start gap-3">
                <span className="grid size-8 shrink-0 place-items-center rounded-full bg-surface text-brand">
                  <Icon className="h-4 w-4" />
                </span>
                <span>
                  <span className="block whitespace-nowrap text-sm font-semibold text-ink">
                    {title}
                  </span>
                  <span className="block text-xs text-subtle">{desc}</span>
                </span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="mx-auto flex w-full max-w-[1230px] flex-col items-center gap-2 border-t border-border py-5 text-xs text-subtle sm:flex-row sm:justify-between">
        <p>© 2026 VeggiePal. Tất cả quyền được bảo lưu.</p>
        <p className="flex items-center gap-1.5 text-brand">
          <Leaf className="h-3.5 w-3.5" /> Ăn chay hôm nay • Khỏe mạnh ngày mai
        </p>
        <p className="flex items-center gap-1">
          Made with <Heart className="h-3.5 w-3.5 fill-danger text-danger" />{" "}
          for a greener world
        </p>
      </div>
    </footer>
  );
}
