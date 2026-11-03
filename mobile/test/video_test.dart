import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/video/data/video_models.dart';
import 'package:VeggiePal/features/video/data/video_repository.dart';

/// ApiClient giả: ghi lại lời gọi và trả / ném theo kịch bản, không đụng tới mạng.
class FakeApi extends ApiClient {
  final posts = <String, Object?>{};
  Object? getResult;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = getResult;
    if (r is Exception) throw r;
    return r;
  }

  @override
  Future<dynamic> post(String path,
      {Object? body,
      Map<String, String>? headers,
      ProgressCallback? onSendProgress,
      Duration? receiveTimeout}) async {
    posts[path] = body;
    return {
      'id': 1,
      'authorId': 2,
      'title': 'Phở chay',
      'sourceType': 'YOUTUBE',
      'videoUrl': 'https://www.youtube.com/embed/dQw4w9WgXcQ',
      'status': 'DRAFT',
    };
  }
}

Map<String, dynamic> _videoJson({String source = 'YOUTUBE', String status = 'PUBLISHED'}) => {
      'id': 5,
      'authorId': 9,
      'categoryId': 3,
      'categoryName': 'Món chính',
      'title': 'Phở chay',
      'description': 'Nước dùng ngọt thanh',
      'sourceType': source,
      'videoUrl': source == 'YOUTUBE'
          ? 'https://www.youtube.com/embed/dQw4w9WgXcQ'
          : 'https://res.cloudinary.com/x/video/upload/v1/videos/5/a.mp4',
      'thumbnailUrl': null,
      'status': status,
      'viewCount': 12,
      'publishedAt': '2026-10-20T08:00:00',
      'moderationReason': null,
    };

void main() {
  setUp(() => dotenv.loadFromString(envString: 'APP=test'));

  group('extractYouTubeId', () {
    test('nhận các dạng link được backend hỗ trợ', () {
      const id = 'dQw4w9WgXcQ';
      expect(extractYouTubeId('https://youtu.be/$id'), id);
      expect(extractYouTubeId('https://www.youtube.com/watch?v=$id&t=5s'), id);
      expect(extractYouTubeId('https://m.youtube.com/watch?v=$id'), id);
      expect(extractYouTubeId('https://www.youtube.com/embed/$id'), id);
      expect(extractYouTubeId('http://youtube.com/shorts/$id'), id);
      expect(extractYouTubeId('  https://youtu.be/$id  '), id);
    });

    test('từ chối link không phải YouTube, sai mã hoặc sai giao thức', () {
      expect(extractYouTubeId(null), isNull);
      expect(extractYouTubeId('dQw4w9WgXcQ'), isNull);
      expect(extractYouTubeId('https://vimeo.com/123456789'), isNull);
      expect(extractYouTubeId('https://www.youtube.com/watch?v=ngan'), isNull);
      expect(extractYouTubeId('https://www.youtube.com/channel/abc'), isNull);
      expect(extractYouTubeId('ftp://youtu.be/dQw4w9WgXcQ'), isNull);
    });
  });

  test('validateVideoFile: chỉ .mp4 và tối đa 30MB', () {
    expect(validateVideoFile(name: 'a.MP4', bytes: 1000), isNull);
    expect(validateVideoFile(name: 'a.mov', bytes: 1000), contains('.mp4'));
    expect(validateVideoFile(name: 'a.mp4', bytes: VideoLimits.maxFileBytes + 1), contains('30MB'));
    expect(validateVideoFile(name: 'a.mp4', bytes: VideoLimits.maxFileBytes), isNull);
  });

  group('Video.fromJson', () {
    test('video YouTube lấy mã từ link nhúng', () {
      final v = Video.fromJson(_videoJson());
      expect(v.isYoutube, isTrue);
      expect(v.youtubeId, 'dQw4w9WgXcQ');
      expect(v.viewCount, 12);
      expect(v.categoryName, 'Món chính');
    });

    test('video tải lên không có mã YouTube', () {
      final v = Video.fromJson(_videoJson(source: 'UPLOAD'));
      expect(v.isYoutube, isFalse);
      expect(v.youtubeId, isNull);
    });
  });

  test('videoOutcome thông báo đúng theo trạng thái và lý do kiểm duyệt', () {
    Video v(String status, {String? reason}) =>
        Video.fromJson({..._videoJson(status: status), 'moderationReason': reason});
    expect(videoOutcome(v('PUBLISHED')).needsDialog, isFalse);
    expect(videoOutcome(v('DRAFT')).message, contains('bản nháp'));
    final rejected = videoOutcome(v('REJECTED', reason: 'Có nội dung động vật'));
    expect(rejected.needsDialog, isTrue);
    expect(rejected.message, contains('Có nội dung động vật'));
    expect(videoOutcome(v('PENDING')).needsDialog, isTrue);
    expect(videoOutcome(v('BANNED')).title, contains('gỡ'));
  });

  test('VideoRepository.create gửi link YouTube dạng multipart, không kèm tệp', () async {
    final api = FakeApi();
    final v = await VideoRepository(api).create(
        title: 'Phở chay', categoryId: 3, youtubeUrl: 'https://youtu.be/dQw4w9WgXcQ', publish: false);
    expect(v.status, 'DRAFT');
    final form = api.posts[Endpoints.videos] as FormData;
    final fields = {for (final f in form.fields) f.key: f.value};
    expect(fields['title'], 'Phở chay');
    expect(fields['categoryId'], '3');
    expect(fields['publish'], 'false');
    expect(fields['youtubeUrl'], 'https://youtu.be/dQw4w9WgXcQ');
    expect(fields.containsKey('description'), isFalse); // mô tả trống thì không gửi
    expect(form.files, isEmpty);
  });
}
