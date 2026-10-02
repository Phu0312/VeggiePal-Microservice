import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Toàn bộ endpoint đi qua API Gateway (gateway tự StripPrefix tiền tố /api).
class Endpoints {
  Endpoints._();

  /// Gateway chạy cổng 18080. Emulator Android không thấy `localhost` của máy host,
  /// phải dùng 10.0.2.2. Thứ tự ưu tiên: --dart-define=API_BASE_URL=... > `.env` > mặc định theo nền tảng.
  static String get baseUrl {
    const define = String.fromEnvironment('API_BASE_URL');
    if (define.isNotEmpty) return define;
    final fromEnv = dotenv.maybeGet('API_BASE_URL');
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:18080/api';
    return 'http://localhost:18080/api';
  }

  // ---- Identity ----
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const me = '/users/me';
  static const myPassword = '/users/me/password';
  static const myAvatar = '/users/me/avatar';
  static const usersBatch = '/users/batch';
  static String adminUser(int id) => '/admin/users/$id';
  static const adminUsers = '/admin/users';
  static String adminUserStatus(int id) => '/admin/users/$id/status';

  // ---- Blog service ----
  static const blogs = '/blogs';
  static const myBlogs = '/blogs/me';
  static String blogById(int id) => '/blogs/$id';
  static const videos = '/videos';
  static String videoById(int id) => '/videos/$id';
  static String videoSummarize(int id) => '/videos/$id/summarize';
  static const categories = '/categories';
  static const comments = '/comments';
  static const moderationQueue = '/admin/moderation/queue';
  static String moderationReview(int id) => '/admin/moderation/$id/review';

  // ---- Nutrition service ----
  static const allergens = '/nutrition/allergens';
  static const myAllergies = '/nutrition/me/allergies';
  static String allergiesOfUser(int userId) => '/nutrition/allergies/user/$userId';
  static const healthRecords = '/nutrition/me/health-records';
  static String healthRecordById(int id) => '/nutrition/me/health-records/$id';
  static const healthRecordLatest = '/nutrition/me/health-records/latest';
  static const mealPlans = '/nutrition/meal-plans';
  static const mealPlanGenerate = '/nutrition/meal-plans/generate';
  static String mealPlanReplace(int id) => '/nutrition/meal-plans/$id/replace-meal';
  static const recipes = '/nutrition/recipes';
  static String recipeById(int id) => '/nutrition/recipes/$id';
  static const myIngredients = '/nutrition/me/ingredients';
  static String myIngredientById(int id) => '/nutrition/me/ingredients/$id';
  static const restaurantsNearby = '/restaurants/nearby';
  static const chatGuest = '/ai/chat/guest';
  static const chat = '/ai/chat';
  static const aiMetrics = '/admin/ai/metrics';
}
