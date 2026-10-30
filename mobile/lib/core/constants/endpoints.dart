import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Toàn bộ endpoint đi qua API Gateway (gateway tự StripPrefix tiền tố /api).
class Endpoints {
  Endpoints._();

  /// Gateway chạy cổng 9080. Emulator Android không thấy `localhost` của máy host,
  /// phải dùng 10.0.2.2. Thứ tự ưu tiên: --dart-define=API_BASE_URL=... > `.env` > mặc định theo nền tảng.
  static String get baseUrl {
    const define = String.fromEnvironment('API_BASE_URL');
    if (define.isNotEmpty) return define;
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:9080/api';
    return 'http://localhost:9080/api';
  }

  // ---- Identity ----
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const googleLogin = '/auth/google';
  static const forgotPassword = '/auth/forgot-password';
  static const verifyOtp = '/auth/verify-otp';
  static const resetPassword = '/auth/reset-password';
  static const sendVerification = '/auth/send-verification';
  static const verifyEmail = '/auth/verify-email';
  static const refreshToken = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/users/me';
  static const myPassword = '/users/me/password';
  static const myAvatar = '/users/me/avatar';
  static const usersBatch = '/users/batch';

  // ---- Blog service ----
  static const blogs = '/blogs';
  static const myBlogs = '/blogs/me';
  static String blogById(int id) => '/blogs/$id';
  static String blogRelated(int id) => '/blogs/$id/related';
  static String blogSubmit(int id) => '/blogs/$id/submit';
  static String blogThumbnail(int id) => '/blogs/$id/thumbnail';
  static String blogVote(int id) => '/blogs/$id/vote';
  static const myBlogVotes = '/blogs/me/votes';
  static String categoryById(int id) => '/categories/$id';
  static String commentReplies(int id) => '/comments/$id/replies';
  static String commentById(int id) => '/comments/$id';
  static const videos = '/videos';
  static const myVideos = '/videos/me';
  static String videoById(int id) => '/videos/$id';
  static String videoSubmit(int id) => '/videos/$id/submit';
  static const categories = '/categories';
  static const comments = '/comments';

  // ---- Nutrition service ----
  static const allergens = '/nutrition/allergens';
  static const myAllergies = '/nutrition/me/allergies';
  static const healthRecords = '/nutrition/me/health-records';
  static String healthRecordById(int id) => '/nutrition/me/health-records/$id';
  static const healthRecordLatest = '/nutrition/me/health-records/latest';
  // ---- AI service: thực đơn tuần ----
  static const aiMealPlans = '/ai/meal-plans';
  static String aiMealPlan(int id) => '/ai/meal-plans/$id';
  static String aiMealPlanReplace(int id) => '/ai/meal-plans/$id/replace';
  static String aiMealPlanFavorite(int id) => '/ai/meal-plans/$id/favorite';
  static const aiMealPlanFavorites = '/ai/meal-plans/favorites';
  static String aiMealPlanVersions(int id) => '/ai/meal-plans/$id/versions';
  static const aiNutritionTarget = '/ai/meal-plans/nutrition-target';

  // ---- Recipe service ----
  static const recipes = '/recipes';
  static const myRecipes = '/recipes/me';
  static String recipeById(int id) => '/recipes/$id';
  static String recipePublish(int id) => '/recipes/$id/publish';
  static const ingredients = '/ingredients';
  static String ingredientById(int id) => '/ingredients/$id';

  static const restaurantsNearby = '/restaurants/nearby';
  // ---- AI service: bóc tách công thức từ video ----
  static const videoJobs = '/ai/videos';
  static const videoProcess = '/ai/videos/process';
  static const videoProcessExisting = '/ai/videos/process-existing';
  static String videoRecipe(int videoId) => '/ai/videos/by-video/$videoId';
  static String videoJob(int id) => '/ai/videos/$id';

  // ---- AI service: gợi ý nội dung ----
  static const aiRecommendations = '/ai/recommendations';

  // ---- AI service: chatbot ----
  static const chatGuestSessions = '/ai/chat/guest-sessions';
  static const chatGuest = '/ai/chat/guest';
  static const chat = '/ai/chat';
  static const chatConversations = '/ai/chat/conversations';
  static String chatConversation(int id) => '/ai/chat/conversations/$id';

  // ---- Payment service: gói thành viên và thanh toán PayOS ----
  static const paymentPlans = '/payments/plans';
  static const paymentCheckout = '/payments/checkout';
  static String paymentOrder(int id) => '/payments/orders/$id';
  static String paymentOrderCancel(int id) => '/payments/orders/$id/cancel';
  static const paymentHistory = '/payments/history';
  static const mySubscription = '/subscriptions/me';

  // ---- Quản trị ----
  static const aiModeration = '/ai/admin/moderation';
  static String aiModerationCase(int id) => '/ai/admin/moderation/$id';
  static const aiUsageSummary = '/ai/admin/monitoring/summary';
  static const aiUsageLogs = '/ai/admin/monitoring/logs/search';
  static const aiModels = '/ai/admin/monitoring/models';
  static const aiLimits = '/ai/admin/monitoring/limits';
  static const adminUsers = '/admin/users';
  static String adminUserStatus(int id) => '/admin/users/$id/status';
  static String adminUserRole(int id) => '/admin/users/$id/role';
  static const adminPaymentSummary = '/admin/payments/summary';
  static const adminPaymentStatistics = '/admin/payments/statistics';
  static const adminPaymentRevenue = '/admin/payments/revenue';
  static const adminPaymentOrders = '/admin/payments/orders';
}
