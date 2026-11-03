// Video của cộng đồng (blog-service: `/videos`).

import '../../../core/utils/moderation.dart';

/// Giới hạn khớp backend.
class VideoLimits {
  VideoLimits._();
  static const maxFileBytes = 30 * 1024 * 1024; // video.max-file-size của blog-service
  static const titleMax = 150;
  static const descriptionMax = 5000;
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

/// Một nguyên liệu trong phần dinh dưỡng của video (VideoNutritionResponse.IngredientLine).
class VideoIngredient {
  final String name;
  final String? amount;
  const VideoIngredient(this.name, [this.amount]);
}

/// Dinh dưỡng và nguyên liệu do người đăng khai báo cho video (blog-service: VideoNutritionResponse).
class VideoNutrition {
  final String? servingLabel;
  final int? kcal;
  final double? protein, carbs, fat, fiber;
  final List<VideoIngredient> ingredients;

  const VideoNutrition(
      {this.servingLabel, this.kcal, this.protein, this.carbs, this.fat, this.fiber, this.ingredients = const []});

  factory VideoNutrition.fromJson(Map<String, dynamic> j) => VideoNutrition(
        servingLabel: j['servingLabel'] as String?,
        kcal: (j['kcal'] as num?)?.toInt(),
        protein: (j['proteinG'] as num?)?.toDouble(),
        carbs: (j['carbsG'] as num?)?.toDouble(),
        fat: (j['fatG'] as num?)?.toDouble(),
        fiber: (j['fiberG'] as num?)?.toDouble(),
        ingredients: [
          for (final i in (j['ingredients'] as List? ?? const []))
            VideoIngredient('${(i as Map)['name'] ?? ''}', i['amount'] as String?),
        ],
      );

  bool get hasMacros => kcal != null || protein != null || carbs != null || fat != null || fiber != null;

  /// Nội dung gửi lên PUT /videos/{id}/nutrition.
  Map<String, dynamic> toJson() => {
        'servingLabel': servingLabel,
        'kcal': kcal,
        'proteinG': protein,
        'carbsG': carbs,
        'fatG': fat,
        'fiberG': fiber,
        'ingredients': [
          for (final i in ingredients) {'name': i.name, 'amount': i.amount},
        ],
      };

  /// Đọc ô nhập "mỗi dòng một nguyên liệu, dạng `tên | lượng`". Dòng trống bị bỏ qua.
  static List<VideoIngredient> parseIngredientLines(String text) {
    final result = <VideoIngredient>[];
    for (final raw in text.split(RegExp(r'\r?\n'))) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final sep = line.indexOf('|');
      final name = (sep < 0 ? line : line.substring(0, sep)).trim();
      final amount = sep < 0 ? '' : line.substring(sep + 1).trim();
      if (name.isNotEmpty) result.add(VideoIngredient(name, amount.isEmpty ? null : amount));
    }
    return result;
  }

  /// Ngược lại của [parseIngredientLines], để điền vào ô nhập khi sửa.
  static String ingredientLines(List<VideoIngredient> items) =>
      items.map((i) => (i.amount ?? '').isEmpty ? i.name : '${i.name} | ${i.amount}').join('\n');
}

/// Phiếu bầu của tôi và điểm hiện tại của một video (blog-service: VoteResponse với videoId).
class VideoVote {
  final int videoId;
  final int? myVote; // 1, -1 hoặc null (chưa bầu)
  final int? voteScore; // null khi lấy theo GET /videos/me/votes
  const VideoVote(this.videoId, this.myVote, this.voteScore);

  factory VideoVote.fromJson(Map<String, dynamic> j) =>
      VideoVote((j['videoId'] as num).toInt(), (j['myVote'] as num?)?.toInt(), (j['voteScore'] as num?)?.toInt());
}

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
  final int voteScore;
  final VideoNutrition? nutrition; // null khi người đăng chưa khai báo
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
    this.voteScore = 0,
    this.nutrition,
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
        voteScore: (j['voteScore'] as num?)?.toInt() ?? 0,
        nutrition: j['nutrition'] is Map ? VideoNutrition.fromJson(Map<String, dynamic>.from(j['nutrition'] as Map)) : null,
        publishedAt: j['publishedAt'] == null ? null : DateTime.tryParse('${j['publishedAt']}'),
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
        moderationReason: j['moderationReason'] as String?,
      );

  bool get isYoutube => sourceType == 'YOUTUBE';

  Video withNutrition(VideoNutrition? n) => Video(
        id: id,
        authorId: authorId,
        categoryId: categoryId,
        categoryName: categoryName,
        title: title,
        description: description,
        sourceType: sourceType,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        status: status,
        viewCount: viewCount,
        voteScore: voteScore,
        nutrition: n,
        publishedAt: publishedAt,
        createdAt: createdAt,
        moderationReason: moderationReason,
      );

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

/// "12.3 MB"
String formatFileSize(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

/// Kết quả hiển thị cho người dùng sau khi lưu / đăng / gửi duyệt một video, theo trạng thái BE trả về.
/// [needsDialog] = true khi cần popup (chờ duyệt hoặc bị từ chối kèm lý do), ngược lại chỉ cần snack.
({String title, String message, bool needsDialog}) videoOutcome(Video v) {
  final reason = moderationReasonVi(v.moderationReason ?? '');
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
