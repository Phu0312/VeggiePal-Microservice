import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../constants/endpoints.dart';
import '../storage/session_store.dart';
import 'error_messages.dart';

/// Lỗi nghiệp vụ/mạng đã chuẩn hoá để repository và UI xử lý thống nhất.
class ApiException implements Exception {
  final String message;
  final int? code; // `code` trong ApiResponse (vd 2030 = khách hết lượt)
  final int? statusCode;
  final bool isNetwork; // true = không kết nối được máy chủ (chưa bật/mất mạng/timeout)

  ApiException(this.message, {this.code, this.statusCode, this.isNetwork = false});

  @override
  String toString() => message;
}

/// Wrapper Dio: gắn JWT, bóc lớp `ApiResponse{code,message,result}`, đổi lỗi sang [ApiException].
class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) async {
      // Access token sắp/đã hết hạn: đổi token mới trước khi gửi. Lỗi làm mới được AuthController xử lý
      // (đăng xuất nếu BE từ chối); ở đây cứ gửi tiếp, 401 nếu có sẽ do onError bên dưới xử lý.
      final t = token;
      if (t != null && _canRefresh(o.path) && SessionStore.isJwtExpired(t, leeway: _refreshLeeway)) {
        await refreshSession!();
      }
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }, onError: (e, h) async {
      // 401 trên request đã gắn token của phiên hiện tại = phiên hết hạn/bị thu hồi.
      final req = e.requestOptions;
      final sent = req.headers['Authorization'];
      if (e.response?.statusCode == 401 && sent != null && sent == 'Bearer $token' && !_isAuthPath(req.path)) {
        // Thử đổi refresh token lấy access token mới rồi gửi lại đúng một lần. Request multipart không gửi lại
        // được (luồng dữ liệu đã đọc hết): chỉ làm mới để lần thử sau của người dùng thành công.
        if (_canRefresh(req.path) && req.extra['retried'] != true) {
          final ok = await refreshSession!();
          if (!ok) return h.next(e); // BE từ chối thì AuthController đã đăng xuất; mất mạng thì báo lỗi như thường
          if (req.data is! FormData) {
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer $token';
            try {
              return h.resolve(await _dio.fetch(req));
            } on DioException catch (retryError) {
              return h.next(retryError);
            }
          }
          return h.next(e);
        }
        onSessionExpired?.call();
      }
      h.next(e);
    }));
  }

  /// Làm mới access token trước khi hết hạn chừng này để request không chết giữa đường.
  static const _refreshLeeway = Duration(seconds: 30);

  /// Các endpoint /auth/* tự xử lý phiên của mình (đăng nhập, làm mới, đăng xuất...), không đi qua cơ chế làm mới.
  static bool _isAuthPath(String path) => path.startsWith('/auth/');

  bool _canRefresh(String path) => refreshToken != null && refreshSession != null && !_isAuthPath(path);

  /// Dio bên dưới, để test thay `httpClientAdapter`.
  @visibleForTesting
  Dio get dio => _dio;

  late final Dio _dio;

  /// JWT hiện tại (AuthController cập nhật khi đăng nhập/đăng xuất).
  String? token;

  /// Refresh token của phiên hiện tại (AuthController cập nhật cùng với [token]).
  String? refreshToken;

  /// AuthController đăng ký: đổi [refreshToken] lấy token mới và cập nhật [token]. Trả `false` nếu không làm mới
  /// được (BE từ chối, hoặc không kết nối được máy chủ). Chỉ được gọi khi [refreshToken] khác null.
  Future<bool> Function()? refreshSession;

  /// Được gọi khi BE trả 401 cho request đang dùng token của phiên hiện tại mà không làm mới được
  /// (AuthController đăng ký).
  void Function()? onSessionExpired;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  /// [onSendProgress] báo tiến độ tải tệp lên; [receiveTimeout] nới thời gian chờ phản hồi cho các yêu cầu
  /// backend xử lý lâu (vd tải video lên kho lưu trữ).
  Future<dynamic> post(String path,
          {Object? body,
          Map<String, String>? headers,
          ProgressCallback? onSendProgress,
          Duration? receiveTimeout}) =>
      _send(() => _dio.post(path,
          data: body,
          onSendProgress: onSendProgress,
          options: Options(headers: headers, receiveTimeout: receiveTimeout)));

  Future<dynamic> put(String path, {Object? body}) =>
      _send(() => _dio.put(path, data: body));

  Future<dynamic> patch(String path, {Object? body}) =>
      _send(() => _dio.patch(path, data: body));

  Future<dynamic> delete(String path) => _send(() => _dio.delete(path));

  Future<dynamic> _send(Future<Response> Function() call) async {
    try {
      final res = await call();
      final data = res.data;
      // Envelope thành công có code == 1000; trả về `result`.
      if (data is Map && data.containsKey('code')) {
        if (data['code'] != 1000) {
          final code = data['code'] as int?;
          throw ApiException(localizedError(code, data['message'] as String?), code: code);
        }
        return data['result'];
      }
      return data;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        final code = body['code'] as int?;
        throw ApiException(localizedError(code, '${body['message']}'),
            code: code, statusCode: e.response?.statusCode);
      }
      // Phản hồi không phải ApiResponse của backend (vd trang lỗi HTML từ gateway/proxy).
      final status = e.response?.statusCode;
      if (status != null) {
        throw ApiException('Máy chủ trả về lỗi không hợp lệ (HTTP $status)', statusCode: status);
      }
      throw ApiException('Không thể kết nối máy chủ. Vui lòng kiểm tra backend/mạng rồi thử lại.',
          isNetwork: true);
    }
  }
}

/// Chuyển mọi lỗi (mạng, nghiệp vụ, parse JSON sai định dạng) thành câu thông báo cho người dùng.
String errorMessage(Object e) {
  if (e is ApiException) return e.message;
  if (e is TypeError || e is FormatException) {
    return 'Dữ liệu máy chủ trả về không đúng định dạng dự kiến.';
  }
  return 'Đã xảy ra lỗi: $e';
}

/// Lấy list từ kết quả phân trang (Spring `content` / PageResponse `items`) hoặc List thuần.
List<dynamic> asList(dynamic result) {
  if (result is List) return result;
  if (result is Map) {
    final l = result['items'] ?? result['content'];
    if (l is List) return l;
  }
  return const [];
}
