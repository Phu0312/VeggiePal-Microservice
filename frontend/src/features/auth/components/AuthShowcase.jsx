import { Leaf, Salad, Sprout } from "lucide-react";

import Logo from "@/shared/components/Logo";

export default function AuthShowcase() {
  return (
    <div className="relative z-10 hidden w-[50%] shrink-0 flex-col items-start p-6 lg:flex">
      <Logo light tagline className="absolute left-6 top-6" markClassName="size-12" />

      <div className="mx-auto mt-28 flex max-w-[340px] flex-col items-center gap-6 text-center">
        <div className="flex items-center gap-3 text-white/80">
          <Leaf className="size-6" />
          <Salad className="size-9" />
          <Sprout className="size-6" />
        </div>
        <p className="font-heading text-[22px] font-extrabold leading-relaxed tracking-tight text-white">
          "CÙNG NHAU XÂY DỰNG LỐI SỐNG XANH, KHỎE MẠNH VÀ HẠNH PHÚC MỖI NGÀY NHÉ"
        </p>
      </div>
    </div>
  );
}
