import { Routes, Route, Navigate } from "react-router-dom";

import AuthScreen from "@/features/auth/pages/AuthScreen";
import AdminRoute from "@/features/auth/components/AdminRoute";
import ProtectedRoute from "@/features/auth/components/ProtectedRoute";
import { useAuthStore, selectIsAuthenticated } from "@/features/auth/store/authStore";
import { ADMIN_HOME_PATH, isAdmin } from "@/features/auth/utils/roleRedirect";
import HomeScreen from "@/features/home/pages/HomeScreen";
import MealPlannerScreen from "@/features/meal-planner/pages/MealPlannerScreen";
import RestaurantMapScreen from "@/features/restaurant-map/pages/RestaurantMapScreen";
import VideoHomeScreen from "@/features/video/pages/VideoHomeScreen";
import VideoWatchScreen from "@/features/video/pages/VideoWatchScreen";
import VideoFormScreen from "@/features/video/pages/VideoFormScreen";
import ProfileScreen from "@/features/profile/pages/ProfileScreen";
import EditProfileScreen from "@/features/profile/pages/EditProfileScreen";
import ChatbotScreen from "@/features/chatbot/pages/ChatbotScreen";
import BlogScreen from "@/features/blog/pages/BlogScreen";
import BlogDetailScreen from "@/features/blog/pages/BlogDetailScreen";
import AdminLayout from "@/features/admin/components/AdminLayout";
import AdminCategoriesScreen from "@/features/admin/pages/AdminCategoriesScreen";
import AdminDashboardScreen from "@/features/admin/pages/AdminDashboardScreen";
import AdminAiMonitoringScreen from "@/features/admin/pages/AdminAiMonitoringScreen";
import AdminPaymentsScreen from "@/features/admin/pages/AdminPaymentsScreen";
import AdminModerationScreen from "@/features/admin/pages/AdminModerationScreen";
import AdminIngredientsScreen from "@/features/admin/pages/AdminIngredientsScreen";
import BlogFormScreen from "@/features/blog/pages/BlogFormScreen";
import RecipeListScreen from "@/features/recipe/pages/RecipeListScreen";
import RecipeDetailScreen from "@/features/recipe/pages/RecipeDetailScreen";
import RecipeFormScreen from "@/features/recipe/pages/RecipeFormScreen";
import MyContentScreen from "@/features/my-content/pages/MyContentScreen";
import PricingScreen from "@/features/payment/pages/PricingScreen";
import CheckoutScreen from "@/features/payment/pages/CheckoutScreen";
import PaymentSuccessScreen from "@/features/payment/pages/PaymentSuccessScreen";
import PaymentCancelScreen from "@/features/payment/pages/PaymentCancelScreen";
import PaymentHistoryScreen from "@/features/payment/pages/PaymentHistoryScreen";

export default function AppRoutes() {
  return (
    <Routes>
      <Route
        path="/login"
        element={
          <RedirectIfAuthenticated>
            <AuthScreen />
          </RedirectIfAuthenticated>
        }
      />
      <Route
        path="/register"
        element={
          <RedirectIfAuthenticated>
            <AuthScreen />
          </RedirectIfAuthenticated>
        }
      />
      <Route path="/forgot-password" element={<AuthScreen />} />
      <Route path="/verify-otp" element={<AuthScreen />} />
      <Route path="/" element={<HomeScreen />} />

      {/* Blog công khai với khách (BE cho GET /blogs không cần token) */}
      <Route path="/blog" element={<BlogScreen />} />
      <Route
        path="/blog/new"
        element={
          <ProtectedRoute>
            <BlogFormScreen />
          </ProtectedRoute>
        }
      />
      <Route path="/blog/:blogId" element={<BlogDetailScreen />} />
      <Route
        path="/blog/:blogId/edit"
        element={
          <ProtectedRoute>
            <BlogFormScreen />
          </ProtectedRoute>
        }
      />

      <Route
        path="/recipes/new"
        element={
          <ProtectedRoute>
            <RecipeFormScreen />
          </ProtectedRoute>
        }
      />
      <Route path="/recipes" element={<RecipeListScreen />} />
      <Route path="/recipes/:recipeId" element={<RecipeDetailScreen />} />
      <Route
        path="/recipes/:recipeId/edit"
        element={
          <ProtectedRoute>
            <RecipeFormScreen />
          </ProtectedRoute>
        }
      />

      <Route
        path="/meal-planner"
        element={
          <ProtectedRoute>
            <MealPlannerScreen />
          </ProtectedRoute>
        }
      />
      <Route
        path="/map"
        element={
          <ProtectedRoute>
            <RestaurantMapScreen />
          </ProtectedRoute>
        }
      />

      {/* Video công khai với khách (BE cho GET /videos và GET /videos/:id không cần token) */}
      <Route path="/videos" element={<VideoHomeScreen />} />
      <Route
        path="/videos/new"
        element={
          <ProtectedRoute>
            <VideoFormScreen />
          </ProtectedRoute>
        }
      />
      <Route
        path="/videos/:videoId/edit"
        element={
          <ProtectedRoute>
            <VideoFormScreen />
          </ProtectedRoute>
        }
      />
      <Route path="/videos/:videoId" element={<VideoWatchScreen />} />

      {/* --- NHÓM PROFILE --- */}
      {/* 1. Trang xem hồ sơ cá nhân */}
      <Route
        path="/profile"
        element={
          <ProtectedRoute>
            <ProfileScreen />
          </ProtectedRoute>
        }
      />
      {/* 2. Trang chỉnh sửa hồ sơ cá nhân (Route riêng) */}
      <Route
        path="/profile/edit"
        element={
          <ProtectedRoute>
            <EditProfileScreen />
          </ProtectedRoute>
        }
      />

      <Route
        path="/my-content"
        element={
          <ProtectedRoute>
            <MyContentScreen />
          </ProtectedRoute>
        }
      />
      {/* Công khai: khách chat thử (POST /ai/chat/guest), thành viên có lịch sử hội thoại */}
      <Route path="/chatbot" element={<ChatbotScreen />} />

      {/* Gói thành viên & Thanh toán payOS */}
      <Route path="/pricing" element={<PricingScreen />} />
      <Route
        path="/checkout/:orderId"
        element={
          <ProtectedRoute>
            <CheckoutScreen />
          </ProtectedRoute>
        }
      />
      <Route
        path="/payment/success"
        element={
          <ProtectedRoute>
            <PaymentSuccessScreen />
          </ProtectedRoute>
        }
      />
      <Route
        path="/payment/cancel"
        element={
          <ProtectedRoute>
            <PaymentCancelScreen />
          </ProtectedRoute>
        }
      />
      <Route
        path="/payment/history"
        element={
          <ProtectedRoute>
            <PaymentHistoryScreen />
          </ProtectedRoute>
        }
      />

      {/* Khu quản trị: chỉ ADMIN (AdminRoute chặn), dùng khung AdminLayout riêng thay vì AppHeader */}
      <Route element={<AdminRoute />}>
        <Route element={<AdminLayout />}>
          <Route path="/admin" element={<AdminDashboardScreen />} />
          <Route path="/admin/categories" element={<AdminCategoriesScreen />} />
          <Route path="/admin/ingredients" element={<AdminIngredientsScreen />} />
          <Route path="/admin/moderation" element={<AdminModerationScreen />} />
          <Route path="/admin/ai-monitoring" element={<AdminAiMonitoringScreen />} />
          <Route path="/admin/payments" element={<AdminPaymentsScreen />} />
        </Route>
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

// Ngược với ProtectedRoute: đã đăng nhập thì không cho vào trang login/register nữa.
function RedirectIfAuthenticated({ children }) {
  const isAuthenticated = useAuthStore(selectIsAuthenticated);
  const user = useAuthStore((s) => s.user);
  if (isAuthenticated) return <Navigate to={isAdmin(user) ? ADMIN_HOME_PATH : "/"} replace />;

  return children;
}
