import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import 'video_models.dart';
/// Backend upload (Cloudinary) can take longer than the default receive timeout.
const _uploadReceiveTimeout = Duration(minutes: 3);

/// blog-service (video cộng đồng, đọc công khai, ghi cần JWT).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class VideoRepository {
  final ApiClient _api;
  VideoRepository(this._api);

  Video _video(dynamic r) => Video.fromJson(Map<String, dynamic>.from(r as Map));

  PageData<T> _page<T>(dynamic r, int page, T Function(dynamic) map) {
    final m = r is Map ? r : const {};
    return PageData(
      asList(r).map(map).toList(),
      (m['page'] as num?)?.toInt() ?? page,
      (m['totalPages'] as num?)?.toInt() ?? 1,
      (m['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  // ---------------- video cộng đồng ----------------

  // POST /videos/{id}/vote {value: 1 | -1}; bầu lại cùng giá trị = rút phiếu. DELETE cùng đường dẫn: bỏ phiếu.
  Future<VideoVote> vote(int id, int value) async {
    final r = await _api.post(Endpoints.videoVote(id), body: {'value': value});
    return VideoVote.fromJson(Map<String, dynamic>.from(r as Map));
  }

  Future<VideoVote> removeVote(int id) async {
    final r = await _api.delete(Endpoints.videoVote(id));
    return VideoVote.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /videos/me/votes?videoIds=1&videoIds=2 -> phiếu bầu của tôi cho từng video.
  Future<List<VideoVote>> myVotes(List<int> videoIds) async {
    if (videoIds.isEmpty) return const [];
    final r = await _api.get(Endpoints.myVideoVotes, query: {'videoIds': videoIds});
    return asList(r).map((e) => VideoVote.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // PUT /videos/{id}/nutrition (chủ video hoặc ADMIN): ghi đè dinh dưỡng và nguyên liệu. Lỗi 3071 = số âm.
  Future<VideoNutrition?> updateNutrition(int id, VideoNutrition n) async {
    final r = await _api.put(Endpoints.videoNutrition(id), body: n.toJson());
    return r is Map ? VideoNutrition.fromJson(Map<String, dynamic>.from(r)) : null;
  }

  // GET /videos?categoryId=&page=&size= : video đã đăng, mới đăng trước (công khai).
  Future<PageData<Video>> published({int? categoryId, int page = 0, int size = 10}) async {
    final r = await _api.get(Endpoints.videos, query: {
      if (categoryId != null) 'categoryId': categoryId,
      'page': page,
      'size': size,
    });
    return _page(r, page, _video);
  }

  // GET /videos/{id} : chỉ video đã đăng; mỗi lần gọi backend tính thêm một lượt xem.
  Future<Video> detail(int id) async => _video(await _api.get(Endpoints.videoById(id)));

  // GET /videos/me?status=&page=&size= : video của tôi ở mọi trạng thái.
  Future<PageData<Video>> mine({String? status, int page = 0, int size = 10}) async {
    final r = await _api.get(Endpoints.myVideos, query: {
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return _page(r, page, _video);
  }

  /// POST /videos (multipart): đúng một trong hai nguồn là [youtubeUrl] hoặc tệp .mp4 ([filePath]).
  /// [publish] = true thì backend kiểm duyệt ngay (đăng / chờ duyệt / từ chối), false thì lưu bản nháp.
  Future<Video> create({
    required String title,
    String description = '',
    required int categoryId,
    String? youtubeUrl,
    String? filePath,
    String? fileName,
    bool publish = true,
    ProgressCallback? onSendProgress,
  }) async {
    final form = FormData.fromMap({
      'title': title,
      if (description.trim().isNotEmpty) 'description': description,
      'categoryId': '$categoryId',
      'publish': '$publish',
      if (youtubeUrl != null) 'youtubeUrl': youtubeUrl,
      if (filePath != null)
        'file': await MultipartFile.fromFile(filePath,
            filename: fileName ?? 'video.mp4', contentType: DioMediaType('video', 'mp4')),
    });
    final r = await _api.post(Endpoints.videos,
        body: form, onSendProgress: onSendProgress, receiveTimeout: _uploadReceiveTimeout);
    return _video(r);
  }

  // PUT /videos/{id} {title, description, categoryId}: nguồn video không đổi được;
  // video đã qua kiểm duyệt sẽ bị kiểm duyệt lại.
  Future<Video> update(int id,
      {required String title, required String description, required int categoryId}) async {
    final r = await _api.put(Endpoints.videoById(id),
        body: {'title': title, 'description': description, 'categoryId': categoryId});
    return _video(r);
  }

  // POST /videos/{id}/submit : gửi bản nháp đi kiểm duyệt.
  Future<Video> submit(int id) async => _video(await _api.post(Endpoints.videoSubmit(id)));

  // DELETE /videos/{id}
  Future<void> delete(int id) async {
    await _api.delete(Endpoints.videoById(id));
  }


}
