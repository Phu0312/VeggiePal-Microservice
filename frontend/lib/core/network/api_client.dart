import 'package:dio/dio.dart';

import '../constants/endpoints.dart';

/// Lỗi nghiệp vụ/mạng đã chuẩn hoá để repository và UI xử lý thống nhất.
class ApiException implements Exception {
  final String message;
  final int? code; // `code` trong ApiResponse (vd 2030 = khách hết lượt)
  final int? statusCode;
  final bool isNetwork; // true = server chưa bật/mất mạng -> kích hoạt Mock Fallback

  ApiException(this.message, {this.code, this.statusCode, this.isNetwork = false});

  @override
  String toString() => message;
}

/// Wrapper Dio: gắn JWT, bóc lớp `ApiResponse{code,message,result}`, đổi lỗi sang [ApiException].
class ApiClient {
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 4), // ngắn để mock fallback phản hồi nhanh
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
    ));
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }));
  }

  late final Dio _dio;

  /// JWT hiện tại (AuthController cập nhật khi đăng nhập/đăng xuất).
  String? token;

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
      // Không có response, hoặc phản hồi không phải ApiResponse của backend (vd trang lỗi HTML
      // từ gateway/proxy) => coi như server không khả dụng để kích hoạt Mock Fallback.
      throw ApiException('Không thể kết nối máy chủ',
          statusCode: e.response?.statusCode, isNetwork: true);
    }
  }
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
