import heroVideo from "@/assets/video/video_homepage.mp4";
import AppHeader from "@/shared/components/AppHeader";
import AppFooter from "@/shared/components/AppFooter";
import HomeHero from "@/features/home/components/HomeHero";
import TrendingRecipesSection from "@/features/home/components/TrendingRecipesSection";
import AiRecommendationsSection from "@/features/home/components/AiRecommendationsSection";
import NutritionLookupSection from "@/features/home/components/NutritionLookupSection";

export default function HomeScreen() {
  return (
    <div className="relative bg-background">
      <div className="fixed inset-x-0 top-3 z-50">
        <AppHeader />
      </div>

      <section className="relative h-screen w-full overflow-hidden">
        <video
          className="absolute inset-0 h-full w-full object-cover"
          src={heroVideo}
          autoPlay
          loop
          muted
          playsInline
        />
        <div aria-hidden className="absolute inset-0 bg-black/40" />
        <div
          aria-hidden
          className="absolute inset-x-0 bottom-0 h-32 bg-gradient-to-b from-transparent to-background sm:h-40"
        />

        <div className="relative z-10 h-full font-home-sans">
          <HomeHero />
        </div>
      </section>

      <TrendingRecipesSection />
      <AiRecommendationsSection />
      <NutritionLookupSection />
      <AppFooter />
    </div>
  );
}
