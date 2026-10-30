import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import 'video_models.dart';

/// Mã lỗi ai-service khi lấy công thức AI của video đã đăng (GET /ai/videos/by-video/{id}).
const _extractionInProgress = 6022;
const _extractionFailed = 6023;
const _sourceUnsupported = 6021;

/// Backend xử lý tải lên (Cloudinary / lưu tệp tạm) có thể lâu hơn thời gian chờ mặc định.
const _uploadReceiveTimeout = Duration(minutes: 3);

/// blog-service (video cộng đồng, đọc công khai, ghi cần JWT) và ai-service (bóc tách công thức từ video).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class VideoRepository {
  final ApiClient _api;
  VideoRepository(this._api);

  Video _video(dynamic r) => Video.fromJson(Map<String, dynamic>.from(r as Map));
  VideoJob _job(dynamic r) => VideoJob.fromJson(Map<String, dynamic>.from(r as Map));

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

  // ---------------- bóc tách công thức bằng AI ----------------

  /// GET /ai/videos/by-video/{id} (công khai, xem không tốn lượt). Các lỗi 6021 / 6022 / 6023 / 404 là trạng thái
  /// bình thường nên được đổi thành [RecipeState]; lỗi khác được ném lại.
  Future<VideoRecipe> recipeOf(int videoId) async {
    try {
      final r = await _api.get(Endpoints.videoRecipe(videoId));
      final extraction = VideoExtraction.tryParse(r is Map ? r['extraction'] : null);
      return extraction == null
          ? const VideoRecipe(RecipeState.none)
          : VideoRecipe(RecipeState.ready, extraction);
    } on ApiException catch (e) {
      if (e.code == _extractionInProgress || e.statusCode == 409) {
        return const VideoRecipe(RecipeState.processing);
      }
      if (e.code == _extractionFailed) return const VideoRecipe(RecipeState.failed);
      if (e.code == _sourceUnsupported) return const VideoRecipe(RecipeState.unsupported);
      if (e.statusCode == 404) return const VideoRecipe(RecipeState.none);
      rethrow;
    }
  }

  // POST /ai/videos/process-existing {videoId} : bóc tách video đã đăng (trừ 1 lượt của gói; kết quả dùng chung).
  Future<VideoJob> processExisting(int videoId) async {
    return _job(await _api.post(Endpoints.videoProcessExisting, body: {'videoId': videoId}));
  }

  /// POST /ai/videos/process (multipart `file`) : bóc tách một tệp video của tôi (trừ 1 lượt của gói).
  /// Backend trả 202 ngay; kết quả lấy bằng [job] / [jobs].
  Future<VideoJob> processFile(String filePath, String fileName, {ProgressCallback? onSendProgress}) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath,
          filename: fileName, contentType: DioMediaType('video', _subtype(fileName))),
    });
    return _job(await _api.post(Endpoints.videoProcess,
        body: form, onSendProgress: onSendProgress, receiveTimeout: _uploadReceiveTimeout));
  }

  // Backend chỉ yêu cầu Content-Type bắt đầu bằng "video/".
  static String _subtype(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return switch (ext) {
      'mov' => 'quicktime',
      'webm' => 'webm',
      'mkv' => 'x-matroska',
      '3gp' => '3gpp',
      _ => 'mp4',
    };
  }

  // GET /ai/videos?page=&size= : lịch sử bóc tách của tôi, mới nhất trước.
  Future<PageData<VideoJob>> jobs({int page = 0, int size = 20}) async {
    final r = await _api.get(Endpoints.videoJobs, query: {'page': page, 'size': size});
    return _page(r, page, _job);
  }

  // GET /ai/videos/{id}
  Future<VideoJob> job(int id) async => _job(await _api.get(Endpoints.videoJob(id)));
}
