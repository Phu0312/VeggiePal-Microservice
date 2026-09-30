import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Mẫu "API + Mock Fallback" dùng cho mọi repository:
///  1. Thử gọi API thật ([real]).
///  2. Nếu server chưa bật / mất mạng / lỗi 5xx -> trả về dữ liệu mock ([mock]) để UI không crash.
///  3. Lỗi nghiệp vụ (4xx: sai mật khẩu, hết lượt, không có quyền...) được ném lại cho UI xử lý.
Future<T> withFallback<T>(Future<T> Function() real, T Function() mock) async {
  try {
    return await real();
  } on ApiException catch (e) {
    if (e.isNetwork || (e.statusCode ?? 0) >= 500) {
      debugPrint('[MockFallback] ${e.message} -> dùng dữ liệu mock');
      return mock();
    }
    rethrow;
  } on TypeError catch (e) {
    // Backend trả JSON khác dự kiến (parse lỗi) -> vẫn giữ UI hoạt động bằng mock.
    debugPrint('[MockFallback] parse lỗi $e -> dùng dữ liệu mock');
    return mock();
  }
}
