import AppHeader from "@/shared/components/AppHeader";
import Reveal from "@/shared/components/Reveal";
import { useProfile } from "@/features/profile/hooks/useProfile";

import ProfileBanner from "@/features/profile/components/ProfileBanner";
import CreatePostBox from "@/features/profile/components/CreatePostBox";
import RecipeFeedCard from "@/features/profile/components/RecipeFeedCard";
import BmiTrackerCard from "@/features/profile/components/BmiTrackerCard";

export default function ProfileScreen() {
  const { profile } = useProfile();

  return (
    <div className="min-h-dvh bg-canvas transition-colors duration-200">
      <AppHeader />

      <main className="mx-auto flex w-full max-w-4xl flex-col gap-6 px-4 py-6 sm:px-6 lg:px-8">
        <Reveal>
          <ProfileBanner profile={profile} />
        </Reveal>

        <Reveal><CreatePostBox profile={profile} /></Reveal>
        <Reveal><RecipeFeedCard /></Reveal>
        <Reveal><BmiTrackerCard /></Reveal>
      </main>

    </div>
  );
}
