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

  test('validateJobFile: tối đa 100MB và không rỗng', () {
    expect(validateJobFile(bytes: 50 * 1024 * 1024), isNull);
    expect(validateJobFile(bytes: VideoLimits.jobMaxBytes + 1), contains('100MB'));
    expect(validateJobFile(bytes: 0), isNotNull);
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

  group('VideoJob', () {
    test('đọc công thức AI, sắp bước theo số thứ tự, đổi thời gian sang giờ máy', () {
      final j = VideoJob.fromJson({
        'id': 4,
        'sourceVideoId': null,
        'status': 'COMPLETED',
        'filename': 'canh-chua.mp4',
        'transcript': 'Hôm nay nấu canh chua',
        'extraction': {
          'title': 'Canh chua chay',
          'ingredients': [
            {'name': 'Dứa', 'quantity': '200g'}
          ],
          'steps': [
            {'number': 2, 'instruction': 'Nấu'},
            {'number': 1, 'instruction': 'Sơ chế'},
          ],
        },
        'error': null,
        'createdAt': '2026-10-20T08:00:00Z',
      });
      expect(j.extraction!.title, 'Canh chua chay');
      expect(j.extraction!.steps.map((s) => s.instruction), ['Sơ chế', 'Nấu']);
      expect(j.extraction!.ingredients.single.quantity, '200g');
      expect(j.createdAt!.isUtc, isFalse);
      expect(j.resultExpired, isFalse);
      expect(j.sourceLabel, 'canh-chua.mp4');
    });

    test('COMPLETED mà không còn nội dung là kết quả đã hết hạn lưu', () {
      final j = VideoJob.fromJson({'id': 1, 'status': 'COMPLETED', 'filename': 'a.mp4', 'extraction': null});
      expect(j.resultExpired, isTrue);
    });

    test('job từ video đã đăng hiển thị số video thay cho tên tệp', () {
      final j = VideoJob.fromJson({'id': 1, 'sourceVideoId': 8, 'status': 'PROCESSING', 'filename': 'blog-video-8.mp4'});
      expect(j.sourceLabel, 'Video đã đăng #8');
      expect(j.processing, isTrue);
    });

    test('describeJobError dịch lý do đã biết, lý do lạ rơi về câu chung', () {
      expect(describeJobError('Video processing queue is full'), contains('bận'));
      expect(describeJobError('lỗi lạ'), contains('thất bại'));
      expect(describeJobError(null), contains('thất bại'));
    });

    test('VideoRecipe.fromJob suy ra trạng thái công thức AI', () {
      VideoJob job(String status, {Object? extraction}) =>
          VideoJob.fromJson({'id': 1, 'status': status, 'extraction': extraction});
      expect(VideoRecipe.fromJob(job('PROCESSING')).state, RecipeState.processing);
      expect(VideoRecipe.fromJob(job('FAILED')).state, RecipeState.failed);
      expect(VideoRecipe.fromJob(job('COMPLETED')).state, RecipeState.none);
      final ready = VideoRecipe.fromJob(job('COMPLETED', extraction: {
        'title': 'Món',
        'ingredients': [],
        'steps': [],
      }));
      expect(ready.state, RecipeState.ready);
    });
  });

  group('VideoRepository.recipeOf', () {
    test('trả công thức khi đã có kết quả', () async {
      final api = FakeApi()
        ..getResult = {
          'sourceVideoId': 5,
          'extraction': {'title': 'Món', 'ingredients': [], 'steps': []},
        };
      final r = await VideoRepository(api).recipeOf(5);
      expect(r.state, RecipeState.ready);
      expect(r.extraction!.title, 'Món');
    });

    test('đổi các mã lỗi 6022 / 6023 / 6021 / 404 thành trạng thái, không ném lỗi', () async {
      final api = FakeApi();
      final repo = VideoRepository(api);
      Future<RecipeState> stateFor(ApiException e) async {
        api.getResult = e;
        return (await repo.recipeOf(5)).state;
      }

      expect(await stateFor(ApiException('x', code: 6022, statusCode: 409)), RecipeState.processing);
      expect(await stateFor(ApiException('x', code: 6023, statusCode: 422)), RecipeState.failed);
      expect(await stateFor(ApiException('x', code: 6021, statusCode: 422)), RecipeState.unsupported);
      expect(await stateFor(ApiException('x', code: 6002, statusCode: 404)), RecipeState.none);
    });

    test('lỗi khác được ném lại', () async {
      final api = FakeApi()..getResult = ApiException('lỗi máy chủ', statusCode: 500);
      await expectLater(VideoRepository(api).recipeOf(5), throwsA(isA<ApiException>()));
    });
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
