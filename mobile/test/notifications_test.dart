import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/home/data/home_repository.dart';
import 'package:VeggiePal/features/notifications/notification_controller.dart';
import 'package:VeggiePal/features/video/data/video_repository.dart';

/// ApiClient giả: trả danh sách bài viết / video của tôi theo kịch bản (hoặc ném lỗi).
class FakeApi extends ApiClient {
  var blogs = <Map<String, dynamic>>[];
  var videos = <Map<String, dynamic>>[];
  var videosFail = false;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path == Endpoints.myBlogs) return blogs;
    if (path == Endpoints.myVideos) {
      if (videosFail) throw ApiException('mất kết nối', isNetwork: true);
      return {'content': videos, 'page': 0, 'totalPages': 1, 'totalElements': videos.length};
    }
    return null;
  }
}

Map<String, dynamic> _blog(int id, String status) => {'id': id, 'title': 'Bài $id', 'status': status};
Map<String, dynamic> _video(int id, String status) =>
    {'id': id, 'authorId': 1, 'title': 'Video $id', 'sourceType': 'YOUTUBE', 'videoUrl': 'u', 'status': status};

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP=test');
    SharedPreferences.setMockInitialValues({});
  });

  test('statusMessage: nội dung theo loại và trạng thái, không báo khi không đổi', () {
    String? m(String noun, String? old, String? now) =>
        NotificationController.statusMessage(noun, 'Tên', old, now);
    expect(m('Video', 'PENDING', 'PUBLISHED'), 'Video "Tên" đã được duyệt và đăng.');
    expect(m('Bài viết', null, 'PUBLISHED'), 'Bài viết "Tên" đã được đăng.');
    expect(m('Video', 'PENDING', 'REJECTED'), 'Video "Tên" không được duyệt.');
    expect(m('Video', 'PUBLISHED', 'BANNED'), contains('bị gỡ'));
    expect(m('Video', 'PENDING', 'PENDING'), isNull);
    expect(m('Video', 'PENDING', 'DRAFT'), isNull); // về nháp thì không cần báo
    expect(m('Video', 'PENDING', null), isNull);
  });

  Future<(FakeApi, NotificationController)> boot() async {
    final api = FakeApi()
      ..blogs = [_blog(1, 'PENDING')]
      ..videos = [_video(1, 'PENDING')];
    final c = NotificationController(HomeRepository(api), VideoRepository(api))..bindUser(1);
    await pumpEventQueue();
    addTearDown(c.dispose);
    return (api, c);
  }

  test('lần đầu chỉ lấy mốc, sau đó video đổi trạng thái thì có thông báo riêng cho video', () async {
    final (api, c) = await boot();
    expect(c.items, isEmpty); // mốc đầu tiên không sinh thông báo

    api.videos = [_video(1, 'PUBLISHED')];
    await c.refresh();
    expect(c.items.map((n) => n.title), ['Video của bạn']);
    expect(c.items.single.body, 'Video "Video 1" đã được duyệt và đăng.');
    expect(c.unread, 1);

    await c.refresh(); // không đổi thì không báo lại
    expect(c.items.length, 1);
  });

  test('bài viết và video đổi cùng lúc đều được báo', () async {
    final (api, c) = await boot();
    api.blogs = [_blog(1, 'REJECTED')];
    api.videos = [_video(1, 'BANNED')];
    await c.refresh();
    expect(c.items.map((n) => n.title).toSet(), {'Bài viết của bạn', 'Video của bạn'});
  });

  test('video mới đăng sau mốc đầu được báo là đã đăng', () async {
    final (api, c) = await boot();
    api.videos = [_video(1, 'PENDING'), _video(2, 'PUBLISHED')];
    await c.refresh();
    expect(c.items.single.body, 'Video "Video 2" đã được đăng.');
  });

  test('ảnh chụp cũ chưa có phần video: lần đầu chỉ lấy mốc, không báo mọi video đang có', () async {
    SharedPreferences.setMockInitialValues({'notif_snapshot_1': '{"1":"PENDING"}'});
    final api = FakeApi()
      ..blogs = [_blog(1, 'PENDING')]
      ..videos = [_video(7, 'PUBLISHED'), _video(8, 'PENDING')];
    final c = NotificationController(HomeRepository(api), VideoRepository(api))..bindUser(1);
    addTearDown(c.dispose);
    await pumpEventQueue();
    expect(c.items, isEmpty);

    api.videos = [_video(7, 'PUBLISHED'), _video(8, 'REJECTED')];
    await c.refresh();
    expect(c.items.single.body, 'Video "Video 8" không được duyệt.');
  });

  test('tải video lỗi không chặn thông báo bài viết và giữ mốc video cũ', () async {
    final (api, c) = await boot();
    api
      ..videosFail = true
      ..blogs = [_blog(1, 'PUBLISHED')];
    await c.refresh();
    expect(c.items.single.body, 'Bài viết "Bài 1" đã được duyệt và đăng.');

    api
      ..videosFail = false
      ..videos = [_video(1, 'PUBLISHED')];
    await c.refresh(); // mốc video vẫn là PENDING nên đổi sang PUBLISHED vẫn được báo
    expect(c.items.first.body, 'Video "Video 1" đã được duyệt và đăng.');
  });
}
