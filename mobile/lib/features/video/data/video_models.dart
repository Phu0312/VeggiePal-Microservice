// Video của cộng đồng (blog-service: `/videos`) và bóc tách công thức từ video bằng AI (ai-service: `/ai/videos`).

/// Giới hạn khớp backend.
class VideoLimits {
  VideoLimits._();
  static const maxFileBytes = 30 * 1024 * 1024; // video.max-file-size của blog-service
  static const titleMax = 150;
  static const descriptionMax = 5000;
  static const jobMaxBytes = 100 * 1024 * 1024; // ai.video.max-file-bytes của ai-service
  static const jobMaxMinutes = 30; // ai.video.max-duration-seconds = 1800
}

/// Tên trạng thái video / bài viết tiếng Việt (ContentStatus).
String videoStatusLabel(String status) => switch (status) {
      'DRAFT' => 'Bản nháp',
      'PENDING' => 'Chờ duyệt',
      'PUBLISHED' => 'Đã đăng',
      'REJECTED' => 'Bị từ chối',
      'BANNED' => 'Đã bị gỡ',
      _ => status,
    };

/// Một video (blog-service: VideoResponse).
class Video {
  final int id;
  final int authorId;
  final int? categoryId;
  final String? categoryName;
  final String title;
  final String? description;
  final String sourceType; // UPLOAD | YOUTUBE
  final String videoUrl; // YOUTUBE: link nhúng; UPLOAD: link .mp4
  final String? thumbnailUrl;
  final String status; // DRAFT | PENDING | PUBLISHED | REJECTED | BANNED
  final int viewCount;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final String? moderationReason; // chỉ có khi kiểm duyệt từ chối / hoãn

  const Video({
    required this.id,
    required this.authorId,
    this.categoryId,
    this.categoryName,
    required this.title,
    this.description,
    required this.sourceType,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.status,
    this.viewCount = 0,
    this.publishedAt,
    this.createdAt,
    this.moderationReason,
  });

  factory Video.fromJson(Map<String, dynamic> j) => Video(
        id: (j['id'] as num).toInt(),
        authorId: (j['authorId'] as num?)?.toInt() ?? 0,
        categoryId: (j['categoryId'] as num?)?.toInt(),
        categoryName: j['categoryName'] as String?,
        title: '${j['title'] ?? ''}',
        description: j['description'] as String?,
        sourceType: '${j['sourceType'] ?? 'YOUTUBE'}',
        videoUrl: '${j['videoUrl'] ?? ''}',
        thumbnailUrl: j['thumbnailUrl'] as String?,
        status: '${j['status'] ?? 'DRAFT'}',
        viewCount: (j['viewCount'] as num?)?.toInt() ?? 0,
        publishedAt: j['publishedAt'] == null ? null : DateTime.tryParse('${j['publishedAt']}'),
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
        moderationReason: j['moderationReason'] as String?,
      );

  bool get isYoutube => sourceType == 'YOUTUBE';

  /// Mã 11 ký tự của video YouTube (lấy từ link nhúng); null với video tải lên.
  String? get youtubeId => isYoutube ? extractYouTubeId(videoUrl) : null;
}

final _youtubeHosts = {'youtube.com', 'www.youtube.com', 'm.youtube.com'};
final _youtubeIdPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Trích mã 11 ký tự của video YouTube từ link người dùng nhập; khớp bộ lọc của backend (YouTubeUrls).
/// Hỗ trợ các dạng youtu.be/ID, youtube.com/watch?v=ID, /embed/ID và /shorts/ID.
String? extractYouTubeId(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url.trim());
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return null;
  final host = uri.host.toLowerCase();
  String? candidate;
  if (host == 'youtu.be') {
    candidate = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
  } else if (_youtubeHosts.contains(host)) {
    if (uri.path == '/watch') {
      candidate = uri.queryParameters['v'];
    } else if (uri.path.startsWith('/embed/')) {
      candidate = uri.path.substring('/embed/'.length);
    } else if (uri.path.startsWith('/shorts/')) {
      candidate = uri.path.substring('/shorts/'.length);
    }
  }
  return candidate != null && _youtubeIdPattern.hasMatch(candidate) ? candidate : null;
}

/// Kiểm tra tệp video đăng lên cộng đồng: bắt buộc .mp4 và ≤ 30MB. Trả lỗi tiếng Việt hoặc null.
String? validateVideoFile({required String name, required int bytes}) {
  if (!name.toLowerCase().endsWith('.mp4')) return 'Video phải là tệp định dạng .mp4';
  if (bytes > VideoLimits.maxFileBytes) return 'Tệp video vượt quá dung lượng cho phép (tối đa 30MB)';
  return null;
}

/// Kiểm tra tệp gửi để AI bóc tách: là video và ≤ 100MB (backend kiểm lại thời lượng ≤ 30 phút). Trả lỗi hoặc null.
String? validateJobFile({required int bytes}) {
  if (bytes <= 0) return 'Tệp video rỗng';
  if (bytes > VideoLimits.jobMaxBytes) return 'Tệp video vượt quá dung lượng cho phép (tối đa 100MB)';
  return null;
}

/// "12.3 MB"
String formatFileSize(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Kết quả hiển thị cho người dùng sau khi lưu / đăng / gửi duyệt một video, theo trạng thái BE trả về.
/// [needsDialog] = true khi cần popup (chờ duyệt hoặc bị từ chối kèm lý do), ngược lại chỉ cần snack.
({String title, String message, bool needsDialog}) videoOutcome(Video v) {
  final reason = (v.moderationReason ?? '').trim();
  switch (v.status) {
    case 'PUBLISHED':
      return (title: 'Đã đăng', message: 'Video "${v.title}" đã được đăng.', needsDialog: false);
    case 'PENDING':
      return (
        title: 'Chờ kiểm duyệt',
        message: 'Video đang chờ quản trị viên kiểm duyệt trước khi hiển thị công khai.'
            '${reason.isEmpty ? '' : '\n\nLý do: $reason'}',
        needsDialog: true,
      );
    case 'REJECTED':
      return (
        title: 'Video không được duyệt',
        message: 'Nội dung vi phạm quy định cộng đồng.${reason.isEmpty ? '' : '\n\nLý do: $reason'}',
        needsDialog: true,
      );
    case 'BANNED':
      return (
        title: 'Video đã bị gỡ',
        message: 'Quản trị viên đã gỡ video này.',
        needsDialog: true,
      );
    default:
      return (title: 'Đã lưu', message: 'Đã lưu bản nháp video.', needsDialog: false);
  }
}

// ---------------- Bóc tách công thức bằng AI ----------------

class ExtractedIngredient {
  final String name;
  final String quantity;
  const ExtractedIngredient(this.name, this.quantity);
}

class ExtractedStep {
  final int number;
  final String instruction;
  const ExtractedStep(this.number, this.instruction);
}

/// Công thức AI bóc tách từ lời trong video: {title, ingredients[{name, quantity}], steps[{number, instruction}]}.
class VideoExtraction {
  final String title;
  final List<ExtractedIngredient> ingredients;
  final List<ExtractedStep> steps;
  const VideoExtraction(this.title, this.ingredients, this.steps);

  /// Null nếu không đúng dạng công thức (vd job cũ đã hết hạn lưu).
  static VideoExtraction? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final title = '${raw['title'] ?? ''}'.trim();
    if (title.isEmpty) return null;
    final steps = [
      for (final s in (raw['steps'] as List? ?? const []))
        if (s is Map) ExtractedStep((s['number'] as num?)?.toInt() ?? 0, '${s['instruction'] ?? ''}'),
    ]..sort((a, b) => a.number.compareTo(b.number));
    return VideoExtraction(
      title,
      [
        for (final i in (raw['ingredients'] as List? ?? const []))
          if (i is Map) ExtractedIngredient('${i['name'] ?? ''}', '${i['quantity'] ?? ''}'),
      ],
      steps,
    );
  }
}

/// Một lượt bóc tách (ai-service: VideoJobResponse).
class VideoJob {
  final int id;
  final int? sourceVideoId; // có khi bóc tách từ video đã đăng
  final String status; // PROCESSING | COMPLETED | FAILED
  final String filename;
  final String? transcript;
  final VideoExtraction? extraction;
  final String? error;
  final DateTime? createdAt;

  const VideoJob({
    required this.id,
    this.sourceVideoId,
    required this.status,
    this.filename = '',
    this.transcript,
    this.extraction,
    this.error,
    this.createdAt,
  });

  factory VideoJob.fromJson(Map<String, dynamic> j) => VideoJob(
        id: (j['id'] as num).toInt(),
        sourceVideoId: (j['sourceVideoId'] as num?)?.toInt(),
        status: '${j['status'] ?? 'PROCESSING'}',
        filename: '${j['filename'] ?? ''}',
        transcript: j['transcript'] as String?,
        extraction: VideoExtraction.tryParse(j['extraction']),
        error: j['error'] as String?,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}')?.toLocal(),
      );

  bool get processing => status == 'PROCESSING';

  /// COMPLETED nhưng không còn nội dung: backend xoá kết quả sau 30 ngày.
  bool get resultExpired => status == 'COMPLETED' && extraction == null;

  /// Job tạo từ video đã đăng có filename do backend tự đặt nên hiển thị số video thay cho tên tệp.
  String get sourceLabel => sourceVideoId != null ? 'Video đã đăng #$sourceVideoId' : filename;
}

String jobStatusLabel(String status) => switch (status) {
      'PROCESSING' => 'Đang xử lý',
      'COMPLETED' => 'Hoàn tất',
      'FAILED' => 'Thất bại',
      _ => status,
    };

// Lý do thất bại do backend ghi vào job (tiếng Anh) -> tiếng Việt.
const _jobErrors = {
  'Video processing failed': 'Không xử lý được video: tệp bị lỗi hoặc dài hơn 30 phút',
  'AI provider returned an invalid response': 'AI chưa trả về kết quả hợp lệ, bạn thử lại sau nhé',
  'Video does not contain sufficient recipe information':
      'Video không có đủ thông tin công thức (nguyên liệu kèm số lượng và các bước) để AI bóc tách',
  'AI provider is temporarily unavailable': 'AI đang tạm thời quá tải, bạn thử lại sau ít phút',
  'AI provider is not configured': 'Tính năng AI chưa được cấu hình trên máy chủ',
  'AI daily quota exceeded': 'AI đã hết hạn mức sử dụng, bạn thử lại sau',
  'Video processing queue is full': 'Hệ thống đang bận, bạn thử lại sau ít phút',
  'Video processing interrupted or timed out':
      'Quá trình xử lý bị gián đoạn hoặc quá lâu, bạn thử gửi lại nhé',
};

/// Lý do job thất bại bằng tiếng Việt; lý do lạ rơi về câu chung.
String describeJobError(String? error) =>
    _jobErrors[error] ?? 'Xử lý video thất bại, bạn thử lại sau nhé';

/// Công thức AI của một video đã đăng (suy ra từ GET /ai/videos/by-video/{id} hoặc job vừa tạo).
enum RecipeState { ready, processing, failed, unsupported, none }

class VideoRecipe {
  final RecipeState state;
  final VideoExtraction? extraction;
  const VideoRecipe(this.state, [this.extraction]);

  /// Từ job do POST /ai/videos/process-existing trả về.
  factory VideoRecipe.fromJob(VideoJob job) {
    if (job.processing) return const VideoRecipe(RecipeState.processing);
    if (job.status == 'COMPLETED' && job.extraction != null) {
      return VideoRecipe(RecipeState.ready, job.extraction);
    }
    if (job.status == 'FAILED') return const VideoRecipe(RecipeState.failed);
    return const VideoRecipe(RecipeState.none);
  }
}
