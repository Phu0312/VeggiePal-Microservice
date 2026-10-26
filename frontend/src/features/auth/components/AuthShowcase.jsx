import logo from "@/assets/img/logo.png";

export default function AuthShowcase() {
  return (
    <div className="relative z-10 hidden w-[50%] shrink-0 flex-col items-start p-4 lg:flex">
      <img src={logo} alt="VeggiePal" className="absolute left-3 top-3 h-20 w-auto" />
        <p className="max-w-[320px] mt-25 mx-auto text-[22px] text-center font-extrabold tracking-tight leading-relaxed text-[#157A42] font-heading">
          "CÙNG NHAU XÂY DỰNG LỐI SỐNG XANH, KHỎE MẠNH VÀ HẠNH PHÚC MỖI NGÀY NHÉ"
        </p>
    </div>
  );
}
