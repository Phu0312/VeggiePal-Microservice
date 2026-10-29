import { Toaster } from "@/components/ui/sonner";
import { useAutoLogout } from "@/features/auth/hooks/useAutoLogout";

import ScrollToTop from "@/shared/components/ScrollToTop";

import AppProvider from "./provider";
import ContentFormHost from "./ContentFormHost";
import AppRoutes from "./routes";

function App() {
  useAutoLogout();

  return (
    <div className="relative min-h-screen">
      <AppProvider>
        <ScrollToTop />
        <AppRoutes />
        <ContentFormHost />
        <Toaster />
      </AppProvider>
    </div>
  );
}

export default App;