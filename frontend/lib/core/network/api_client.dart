import 'package:dio/dio.dart';

import '../constants/endpoints.dart';

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
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }, onError: (e, h) {
      // 401 trên request đã gắn token của phiên hiện tại = phiên hết hạn/bị thu hồi.
      final sent = e.requestOptions.headers['Authorization'];
      if (e.response?.statusCode == 401 && sent != null && sent == 'Bearer $token') {
        onSessionExpired?.call();
      }
      h.next(e);
    }));
  }

  late final Dio _dio;

  /// JWT hiện tại (AuthController cập nhật khi đăng nhập/đăng xuất).
  String? token;

  /// Được gọi khi BE trả 401 cho request đang dùng token của phiên hiện tại (AuthController đăng ký).
  void Function()? onSessionExpired;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? body, Map<String, String>? headers}) =>
      _send(() => _dio.post(path, data: body, options: Options(headers: headers)));

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
          throw ApiException('${data['message'] ?? 'Lỗi'}', code: data['code'] as int?);
        }
        return data['result'];
      }
      return data;
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map && body['message'] != null) {
        throw ApiException('${body['message']}',
            code: body['code'] as int?, statusCode: e.response?.statusCode);
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
