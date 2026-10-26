import { Link } from "react-router-dom";
import { ArrowRight, Play } from "lucide-react";

export default function HomeHero() {
  return (
    <div className="flex h-full flex-col items-center justify-center px-6 pt-20 text-center sm:pt-24">
      <h1 className="max-w-5xl font-display-serif text-3xl leading-[1.1] text-white sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl">
        <span className="font-display-serif italic">THỰC ĐƠN VÀ LỐI SỐNG</span> 
        <br />
        <span className="font-display-serif italic">XANH CHO HÀNH TRÌNH</span> 
        <br />
        <span className="font-display-serif italic">KHỎE MẠNH HƠN</span>
      </h1>

      <p className="mt-4 max-w-md font-sans text-sm font-light leading-relaxed text-white/70 md:mt-5 md:text-base">
        Chúng tôi giúp bạn lên thực đơn thuần chay cân bằng
        <br className="hidden sm:block" />
        và duy trì lối sống xanh bền vững.
      </p>

      <div className="mt-5 flex flex-col items-center gap-4 sm:flex-row md:mt-6">
        <Link
          to="/"
          className="group flex items-center gap-2 rounded-full bg-white px-7 py-3 font-sans text-sm font-medium text-black"
        >
          Khám Phá
          <ArrowRight className="h-4 w-4 transition-transform duration-200 group-hover:translate-x-0.5" />
        </Link>
        <Link
          to="/"
          className="flex items-center gap-2 rounded-full border border-white/40 px-7 py-3 font-sans text-sm text-white transition-colors duration-200 hover:border-white/60 hover:bg-white/10"
        >
          <Play className="h-4 w-4" />
          Xem Giới Thiệu
        </Link>
      </div>
    </div>
  );
}
