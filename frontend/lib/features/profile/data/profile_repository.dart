import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
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

  // PATCH /users/me {fullName, phone, dateOfBirth}; phone "" = xoá số điện thoại.
  Future<UserProfile> updateProfile(
      {required String fullName, required String phone, String? dateOfBirth}) async {
    final r = await _api.patch(Endpoints.me, body: {
      'fullName': fullName,
      'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
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
    final type = _sniffImageType(bytes);
    if (type == null) throw ApiException('Ảnh đại diện phải là JPEG, PNG hoặc WEBP.');
    if (bytes.length > _maxAvatarBytes) {
      throw ApiException('Ảnh đại diện không được vượt quá 2MB.');
    }
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes,
          filename: 'avatar.${type == 'jpeg' ? 'jpg' : type}',
          contentType: DioMediaType('image', type)),
    });
    final r = await _api.post(Endpoints.myAvatar, body: form);
    return UserProfile.fromJson(Map<String, dynamic>.from(r as Map));
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

  // GET /nutrition/allergies/user/{userId} (công khai) -> mã chất gây dị ứng của một người dùng.
  Future<List<String>> allergenCodesOfUser(int userId) async {
    final r = await _api.get(Endpoints.allergiesOfUser(userId));
    return asList(r).map((e) => '$e').toList();
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

  /// Nhận diện loại ảnh theo byte đầu file (không tin vào đuôi tên file vì ảnh có thể đã bị nén lại).
  static String? _sniffImageType(Uint8List b) {
    if (b.length > 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return 'jpeg';
    if (b.length > 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'png';
    if (b.length > 12 &&
        String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
        String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
      return 'webp';
    }
    return null;
  }
}
