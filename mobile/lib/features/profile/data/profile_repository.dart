import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_type.dart';
import 'profile_models.dart';

/// identity-service (hồ sơ cá nhân) + nutrition-service (dị ứng, lịch sử sức khỏe).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class ProfileRepository {
  final ApiClient _api;
  ProfileRepository(this._api);

  static const _maxAvatarBytes = 2 * 1024 * 1024; // backend giới hạn 2MB

  // ---------------- identity-service ----------------

  // GET /users/me
  Future<UserProfile> profile() async {
    final r = await _api.get(Endpoints.me);
    return UserProfile.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PATCH /users/me {fullName, phone, dateOfBirth, gender, activityLevel}; phone "" = xoá số điện thoại,
  // trường null/không gửi = giữ nguyên.
  Future<UserProfile> updateProfile(
      {required String fullName,
      required String phone,
      String? dateOfBirth,
      String? gender,
      String? activityLevel}) async {
    final r = await _api.patch(Endpoints.me, body: {
      'fullName': fullName,
      'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (activityLevel != null) 'activityLevel': activityLevel,
    });
    return UserProfile.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PUT /users/me/password {currentPassword, newPassword}
  Future<void> changePassword(String current, String next) async {
    await _api.put(Endpoints.myPassword,
        body: {'currentPassword': current, 'newPassword': next});
  }

  // POST /users/me/avatar (multipart `file`; JPEG/PNG/WEBP, tối đa 2MB)
  Future<UserProfile> uploadAvatar(Uint8List bytes) async {
    final type = sniffImageType(bytes);
    if (type == null) throw ApiException('Ảnh đại diện phải là JPEG, PNG hoặc WEBP.');
    if (bytes.length > _maxAvatarBytes) {
      throw ApiException('Ảnh đại diện không được vượt quá 2MB.');
    }
    final r = await _api.post(Endpoints.myAvatar,
        body: FormData.fromMap({'file': imagePart(bytes, type)}));
    return UserProfile.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /users/me/favorites?type= : mới lưu trước. Loại lạ mà app chưa biết bị bỏ qua.
  Future<List<FavoriteItem>> favorites({FavoriteType? type}) async {
    final r = await _api.get(Endpoints.myFavorites, query: {if (type != null) 'type': type.code});
    return [
      for (final e in asList(r)) ?FavoriteItem.tryParse(Map<String, dynamic>.from(e as Map)),
    ];
  }

  // POST /users/me/favorites {targetType, targetId, title, imageUrl}: thêm (lưu lại thì cập nhật tiêu đề / ảnh).
  Future<FavoriteItem?> saveFavorite(FavoriteType type, int id, String title, String? imageUrl) async {
    final r = await _api.post(Endpoints.myFavorites, body: {
      'targetType': type.code,
      'targetId': id,
      'title': title.length > 255 ? title.substring(0, 255) : title,
      if ((imageUrl ?? '').isNotEmpty && imageUrl!.length <= 512) 'imageUrl': imageUrl,
    });
    return FavoriteItem.tryParse(Map<String, dynamic>.from(r as Map));
  }

  // DELETE /users/me/favorites/{type}/{id}
  Future<void> removeFavorite(FavoriteType type, int id) async {
    await _api.delete(Endpoints.myFavorite(type.code, id));
  }

  // GET /users/me/badges : đủ 6 huy hiệu kèm trạng thái đã đạt.
  Future<BadgeCollection> badges() async {
    final r = await _api.get(Endpoints.myBadges);
    return BadgeCollection.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // POST /users/me/badges/{code} : mở khoá một huy hiệu (idempotent, gọi lại không báo lỗi).
  Future<void> unlockBadge(String code) async {
    await _api.post(Endpoints.myBadge(code));
  }

  // GET /users/batch?ids=1&ids=2 (công khai, tối đa 50) -> tên + avatar của tác giả.
  Future<List<PublicUser>> publicUsers(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final r = await _api.get(Endpoints.usersBatch, query: {'ids': ids});
    return asList(r)
        .map((e) => PublicUser.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------- nutrition-service: dị ứng ----------------

  // GET /nutrition/allergens (công khai)
  Future<List<Allergen>> allergens() async {
    final r = await _api.get(Endpoints.allergens);
    return asList(r)
        .map((e) => Allergen.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /nutrition/me/allergies
  Future<List<Allergen>> myAllergies() async {
    final r = await _api.get(Endpoints.myAllergies);
    return asList(r)
        .map((e) => Allergen.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // PUT /nutrition/me/allergies {allergenIds}; [] = xoá hết.
  Future<List<Allergen>> saveAllergies(List<int> allergenIds) async {
    final r = await _api.put(Endpoints.myAllergies, body: {'allergenIds': allergenIds});
    return asList(r)
        .map((e) => Allergen.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------- nutrition-service: sức khỏe ----------------

  // GET /nutrition/me/health-records?page&size -> mới nhất trước.
  Future<List<HealthRecord>> healthRecords({int page = 0, int size = 50}) async {
    final r = await _api.get(Endpoints.healthRecords, query: {'page': page, 'size': size});
    return asList(r)
        .map((e) => HealthRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // POST /nutrition/me/health-records {heightCm, weightKg}; BMI do server tính.
  Future<HealthRecord> createHealthRecord(double heightCm, double weightKg) async {
    final r = await _api.post(Endpoints.healthRecords,
        body: {'heightCm': heightCm, 'weightKg': weightKg});
    return HealthRecord.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PUT /nutrition/me/health-records/{id}; giữ nguyên recordedAt, BMI tính lại.
  Future<HealthRecord> updateHealthRecord(int id, double heightCm, double weightKg) async {
    final r = await _api.put(Endpoints.healthRecordById(id),
        body: {'heightCm': heightCm, 'weightKg': weightKg});
    return HealthRecord.fromJson(Map<String, dynamic>.from(r as Map));
  }
}
