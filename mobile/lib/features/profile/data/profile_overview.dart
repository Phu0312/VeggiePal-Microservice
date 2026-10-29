import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart' show PageData;
import '../../home/data/home_repository.dart';
import '../../recipe/data/recipe_models.dart';
import '../../recipe/data/recipe_repository.dart';
import '../../video/data/video_models.dart';
import '../../video/data/video_repository.dart';
import 'profile_models.dart';
import 'profile_repository.dart';

/// Hồ sơ thiếu những trường nào để backend tính nhu cầu calo của thực đơn (ngày sinh, giới tính, mức vận động)
/// hoặc chưa đủ tuổi (backend chỉ tính cho người từ 18 tuổi, lỗi 6021). Rỗng nghĩa là đủ điều kiện.
class CalorieProfileIssue {
  final List<String> missing; // tên trường của GET /users/me: dateOfBirth | gender | activityLevel
  final bool underage;
  const CalorieProfileIssue(this.missing, this.underage);

  bool get hasIssue => missing.isNotEmpty || underage;

  static const fieldLabels = {
    'dateOfBirth': 'ngày sinh',
    'gender': 'giới tính',
    'activityLevel': 'mức độ vận động',
  };

  String get message => underage
      ? 'Thực đơn tính theo calo mục tiêu hiện chỉ dành cho người từ 18 tuổi trở lên.'
      : 'Bổ sung ${missing.map((f) => fieldLabels[f]).join(', ')} để tính nhu cầu calo cho thực đơn.';

  /// Kiểm tra theo hồ sơ; [today] để test cố định ngày.
  static CalorieProfileIssue of(UserProfile p, [DateTime? today]) {
    final missing = [
      if (p.dateOfBirth == null) 'dateOfBirth',
      if ((p.gender ?? '').isEmpty) 'gender',
      if ((p.activityLevel ?? '').isEmpty) 'activityLevel',
    ];
    final dob = p.dateOfBirth;
    var underage = false;
    if (dob != null) {
      final t = today ?? DateTime.now();
      final hadBirthday = t.month > dob.month || (t.month == dob.month && t.day >= dob.day);
      underage = t.year - dob.year - (hadBirthday ? 0 : 1) < 18;
    }
    return CalorieProfileIssue(missing, underage);
  }
}

/// Số liệu của trang Hồ sơ: hồ sơ cá nhân, tổng bài viết / công thức / video của tôi, số chất dị ứng
/// và các chỉ số sức khỏe gần nhất (cho biểu đồ BMI). Mỗi nguồn tải độc lập: một nguồn lỗi không làm mất các nguồn
/// còn lại (phần lỗi hiện dấu "-" và có nút tải lại).
class ProfileOverview extends ChangeNotifier {
  ProfileOverview(this._profiles, this._home, this._recipes, this._videos);

  final ProfileRepository _profiles;
  final HomeRepository _home;
  final RecipeRepository _recipes;
  final VideoRepository _videos;

  /// Số bản ghi sức khỏe lấy cho biểu đồ.
  static const chartSize = 6;

  int? _userId;
  int _epoch = 0;

  UserProfile? profile;
  int? blogs, recipes, videos, allergies;
  List<HealthRecord> health = const []; // mới nhất trước
  bool loading = false;
  bool loaded = false;
  String? error;

  HealthRecord? get latestHealth => health.isEmpty ? null : health.first;

  CalorieProfileIssue? get calorieIssue => profile == null ? null : CalorieProfileIssue.of(profile!);

  /// Gọi khi đăng nhập / đăng xuất (từ ProxyProvider): xoá số liệu của tài khoản trước.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _epoch++;
    profile = null;
    blogs = recipes = videos = allergies = null;
    health = const [];
    loading = loaded = false;
    error = null;
    // Được gọi từ ProxyProvider.update (đang trong build) nên hoãn thông báo sang microtask.
    Future.microtask(notifyListeners);
  }

  /// Tải lần đầu (nếu chưa tải); gọi lại nhiều lần vô hại.
  Future<void> ensureLoaded() async {
    if (_userId == null || loading || loaded) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (_userId == null || loading) return;
    final epoch = _epoch;
    loading = true;
    notifyListeners();

    final errors = <String>[];
    Future<T?> guard<T>(Future<T> f) async {
      try {
        return await f;
      } catch (e) {
        errors.add(errorMessage(e));
        return null;
      }
    }

    final r = await Future.wait<Object?>([
      guard(_profiles.profile()),
      guard(_home.myBlogsTotal()),
      guard(_recipes.mine(size: 1)),
      guard(_videos.mine(size: 1)),
      guard(_profiles.myAllergies()),
      guard(_profiles.healthRecords(size: chartSize)),
    ]);
    if (epoch != _epoch) return;

    profile = (r[0] as UserProfile?) ?? profile;
    blogs = (r[1] as int?) ?? blogs;
    recipes = (r[2] as PageData<Recipe>?)?.totalElements ?? recipes;
    videos = (r[3] as PageData<Video>?)?.totalElements ?? videos;
    final al = r[4] as List<Allergen>?;
    if (al != null) allergies = al.length;
    health = (r[5] as List<HealthRecord>?) ?? health;

    error = errors.isEmpty ? null : errors.first;
    loaded = true;
    loading = false;
    notifyListeners();
  }
}
