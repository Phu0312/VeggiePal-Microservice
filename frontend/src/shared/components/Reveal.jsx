import { useRevealOnScroll } from "@/shared/hooks/useRevealOnScroll";

export default function Reveal({ children, className = "", delay = 0 }) {
  const [ref, visible] = useRevealOnScroll({ threshold: 0.15 });

  return (
    <div
      ref={ref}
      data-reveal
      className={`transition-all duration-1200 ease-[cubic-bezier(0.16,1,0.3,1)] ${
        visible ? "translate-y-0 opacity-100" : "translate-y-8 opacity-0"
      } ${className}`}
      style={{ transitionDelay: visible ? `${delay}ms` : "0ms" }}
    >
      {children}
    </div>
  );
}
