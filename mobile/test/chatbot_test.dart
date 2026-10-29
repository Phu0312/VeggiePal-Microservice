import 'package:dio/dio.dart' show ProgressCallback;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:VeggiePal/core/constants/endpoints.dart';
import 'package:VeggiePal/core/network/api_client.dart';
import 'package:VeggiePal/features/ai_nutrition/data/chat_models.dart';
import 'package:VeggiePal/features/ai_nutrition/data/chat_repository.dart';
import 'package:VeggiePal/features/ai_nutrition/presentation/chat_controller.dart';
import 'package:VeggiePal/features/ai_nutrition/presentation/chat_markdown.dart';

/// ApiClient giả: ghi lại các lời gọi và trả/ném theo kịch bản, không đụng tới mạng.
class FakeApi extends ApiClient {
  final calls = <String>[];
  final bodies = <Object?>[];
  var sessionCounter = 0;

  /// Mỗi phần tử là kết quả (hoặc lỗi) của lần gọi tiếp theo tới /ai/chat/guest.
  final guestResults = <Object>[];
  final memberResults = <Object>[];
  final messagesById = <int, List<Map<String, dynamic>>>{};
  var conversationList = <Map<String, dynamic>>[];

  Object _next(List<Object> queue) {
    final r = queue.removeAt(0);
    if (r is Exception) throw r;
    return r;
  }

  @override
  Future<dynamic> post(String path,
      {Object? body,
      Map<String, String>? headers,
      ProgressCallback? onSendProgress,
      Duration? receiveTimeout}) async {
    calls.add('POST $path');
    bodies.add(body);
    if (path == Endpoints.chatGuestSessions) {
      sessionCounter++;
      return {'guestSession': 'guest-session-number-$sessionCounter', 'expiresAt': '2999-01-01T00:00:00'};
    }
    return _next(path == Endpoints.chatGuest ? guestResults : memberResults);
  }

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    calls.add('GET $path');
    if (path == Endpoints.chatConversations) return conversationList;
    final id = int.parse(path.split('/').last);
    return {'conversation': {'id': id}, 'messages': messagesById[id] ?? []};
  }

  @override
  Future<dynamic> delete(String path) async {
    calls.add('DELETE $path');
  }
}

Map<String, dynamic> _reply(String answer, {int? conversationId, int remaining = 2}) =>
    {'answer': answer, 'conversationId': conversationId, 'remainingRequests': remaining};

void main() {
  setUp(() {
    dotenv.loadFromString(envString: 'APP=test');
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatRepository (khách)', () {
    test('tạo phiên một lần rồi dùng lại phiên còn hạn đã lưu', () async {
      final api = FakeApi()..guestResults.addAll([_reply('a'), _reply('b')]);
      final repo = ChatRepository(api);
      await repo.sendGuest('xin chào');
      await repo.sendGuest('hỏi nữa');
      expect(api.calls.where((c) => c.endsWith('guest-sessions')).length, 1);
      expect((api.bodies.last as Map)['guestSession'], 'guest-session-number-1');
    });

    test('phiên bị từ chối (401) thì tạo phiên mới và gửi lại đúng một lần', () async {
      final api = FakeApi()
        ..guestResults.addAll([ApiException('hết hạn', statusCode: 401, code: 6001), _reply('ok')]);
      final reply = await ChatRepository(api).sendGuest('hỏi');
      expect(reply.answer, 'ok');
      expect(api.sessionCounter, 2);
      expect((api.bodies.last as Map)['guestSession'], 'guest-session-number-2');
    });

    test('lỗi khác 401 (hết lượt) được ném lại, không thử lại', () async {
      final api = FakeApi()..guestResults.add(ApiException('quota', statusCode: 429, code: 6003));
      await expectLater(ChatRepository(api).sendGuest('hỏi'),
          throwsA(isA<ApiException>().having((e) => e.code, 'code', 6003)));
      expect(api.calls.where((c) => c == 'POST ${Endpoints.chatGuest}').length, 1);
    });

    test('phiên đã lưu nhưng hết hạn thì tạo phiên mới', () async {
      SharedPreferences.setMockInitialValues({
        'chat_guest_session': '{"guestSession":"old-old-old-old-old","expiresAt":"2000-01-01T00:00:00"}',
      });
      final api = FakeApi()..guestResults.add(_reply('ok'));
      await ChatRepository(api).sendGuest('hỏi');
      expect(api.sessionCounter, 1);
    });
  });

  group('ChatController', () {
    test('khách: gửi thành công thì có câu trả lời và số lượt còn lại', () async {
      final api = FakeApi()..guestResults.add(_reply('Chào bạn', remaining: 2));
      final chat = ChatController(ChatRepository(api));
      final outcome = await chat.send('  Xin chào  ');
      expect(outcome.ok, isTrue);
      expect(chat.messages.map((m) => m.text), ['Xin chào', 'Chào bạn']);
      expect(chat.messages.map((m) => m.fromUser), [true, false]);
      expect(chat.remaining, 2);
      expect(chat.quotaLabel, 'Dùng thử: còn 2 lượt hỏi hôm nay');
      expect(chat.sending, isFalse);
    });

    test('khách hết lượt: gỡ câu hỏi, báo hết lượt, lần sau không gọi máy chủ nữa', () async {
      final api = FakeApi()..guestResults.add(ApiException('quota', statusCode: 429, code: 6003));
      final chat = ChatController(ChatRepository(api));

      final first = await chat.send('hỏi');
      expect(first.guestQuotaExceeded, isTrue);
      expect(chat.messages, isEmpty);
      expect(chat.remaining, 0);

      final calls = api.calls.length;
      final second = await chat.send('hỏi lại');
      expect(second.guestQuotaExceeded, isTrue);
      expect(api.calls.length, calls);
    });

    test('lỗi máy chủ được dịch sang tiếng Việt và câu hỏi bị gỡ khỏi khung chat', () async {
      final api = FakeApi()..guestResults.add(ApiException('x', statusCode: 503, code: 6004));
      final chat = ChatController(ChatRepository(api));
      final outcome = await chat.send('hỏi');
      expect(outcome.ok, isFalse);
      expect(outcome.guestQuotaExceeded, isFalse);
      expect(outcome.error, contains('tạm thời không khả dụng'));
      expect(chat.messages, isEmpty);
    });

    test('thành viên: tạo cuộc trò chuyện mới rồi nối tiếp bằng conversationId', () async {
      final api = FakeApi()
        ..memberResults.addAll([_reply('một', conversationId: 7, remaining: 9), _reply('hai', conversationId: 7, remaining: 8)])
        ..conversationList = [
          {'id': 7, 'title': 'Xin chào', 'updatedAt': '2026-10-29T10:00:00'}
        ];
      final chat = ChatController(ChatRepository(api))..bindUser(1);
      await pumpEventQueue();

      await chat.send('Xin chào');
      expect(chat.activeId, 7);
      expect((api.bodies.first as Map).containsKey('conversationId'), isFalse);
      await pumpEventQueue();
      expect(chat.activeConversation?.title, 'Xin chào');

      await chat.send('Tiếp nữa');
      expect((api.bodies.last as Map)['conversationId'], 7);
      expect(chat.remaining, 8);
      expect(chat.quotaLabel, 'Còn 8 lượt hỏi hôm nay');
    });

    test('mở lại cuộc trò chuyện cũ, xoá cuộc đang mở thì về cuộc mới', () async {
      final api = FakeApi()
        ..conversationList = [
          {'id': 3, 'title': '', 'updatedAt': '2026-10-29T10:00:00'}
        ]
        ..messagesById[3] = [
          {'id': 1, 'role': 'user', 'content': 'hỏi'},
          {'id': 2, 'role': 'assistant', 'content': 'đáp'},
        ];
      final chat = ChatController(ChatRepository(api))..bindUser(1);
      await pumpEventQueue();
      expect(chat.conversations.single.title, 'Cuộc trò chuyện mới'); // tiêu đề trống

      expect(await chat.open(3), isNull);
      expect(chat.activeId, 3);
      expect(chat.messages.map((m) => m.fromUser), [true, false]);

      expect(await chat.delete(3), isNull);
      expect(chat.activeId, isNull);
      expect(chat.messages, isEmpty);
      expect(chat.conversations, isEmpty);
    });

    test('đăng xuất xoá cuộc trò chuyện của tài khoản trước', () async {
      final api = FakeApi()..memberResults.add(_reply('đáp', conversationId: 1));
      final chat = ChatController(ChatRepository(api))..bindUser(1);
      await pumpEventQueue();
      await chat.send('hỏi');
      expect(chat.messages, isNotEmpty);

      chat.bindUser(null);
      expect(chat.messages, isEmpty);
      expect(chat.activeId, isNull);
      expect(chat.remaining, isNull);
      expect(chat.isMember, isFalse);
    });
  });

  test('chatErrorMessage phân biệt khách và thành viên khi hết lượt', () {
    final quota = ApiException('q', statusCode: 429, code: 6003);
    expect(chatErrorMessage(quota, guest: true), contains('đăng ký hoặc đăng nhập'));
    expect(chatErrorMessage(quota, guest: false), contains('nâng cấp gói'));
    expect(chatErrorMessage(ApiException('x', statusCode: 400, code: 6000), guest: false), contains('4000'));
    expect(chatErrorMessage(ApiException('Không kết nối', isNetwork: true), guest: false), 'Không kết nối');
  });

  test('GuestSession.isUsable chừa 60 giây đệm', () {
    final now = DateTime(2026, 10, 29, 12);
    expect(GuestSession('x', now.add(const Duration(seconds: 90))).isUsable(now), isTrue);
    expect(GuestSession('x', now.add(const Duration(seconds: 30))).isUsable(now), isFalse);
  });

  group('parseChatMarkdown', () {
    test('tiêu đề, danh sách có thứ tự / không thứ tự, đường kẻ, đoạn văn', () {
      final blocks = parseChatMarkdown('''
## Đạm từ thực vật
Đậu hũ giàu đạm.
Nên ăn đa dạng.

- Đậu hũ
* Nấm
1. Bước một
2) Bước hai
---
''');
      expect(blocks[0], isA<MdHeading>().having((b) => b.level, 'level', 2));
      expect((blocks[1] as MdParagraph).text, 'Đậu hũ giàu đạm.\nNên ăn đa dạng.');
      expect((blocks[2] as MdList).ordered, isFalse);
      expect((blocks[2] as MdList).items, ['Đậu hũ', 'Nấm']);
      expect((blocks[3] as MdList).ordered, isTrue);
      expect((blocks[3] as MdList).items, ['Bước một', 'Bước hai']);
      expect(blocks[4], isA<MdRule>());
    });

    test('bảng có dòng tiêu đề, dòng phân cách và các dòng dữ liệu', () {
      final blocks = parseChatMarkdown('| Món | Kcal |\n|---|---|\n| Đậu hũ | 76 |\n| Nấm | 22 |');
      final t = blocks.single as MdTable;
      expect(t.header, ['Món', 'Kcal']);
      expect(t.rows, [
        ['Đậu hũ', '76'],
        ['Nấm', '22']
      ]);
    });

    test('inline: đậm, nghiêng, code, xuống dòng', () {
      final t = parseInline('Ăn **đậu hũ** và *nấm* với `muối`<br>nhé');
      expect(t.map((e) => e.type), [
        MdInlineType.text,
        MdInlineType.bold,
        MdInlineType.text,
        MdInlineType.italic,
        MdInlineType.text,
        MdInlineType.code,
        MdInlineType.lineBreak,
        MdInlineType.text,
      ]);
      expect(t[1].text, 'đậu hũ');
    });

    test('nội dung rỗng không có khối nào', () {
      expect(parseChatMarkdown('  \n\n'), isEmpty);
    });
  });

  testWidgets('ChatMarkdown dựng được tiêu đề, danh sách, bảng thiếu ô và chữ đậm', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: ChatMarkdown(
            '''
## Gợi ý
Ăn **đậu hũ** mỗi ngày.

- Đậu hũ
- Nấm

| Món | Kcal | Đạm |
|---|---|---|
| Đậu hũ | 76 |
| Nấm | 22 | 3 |
''',
            color: Colors.black,
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Gợi ý', findRichText: true), findsOneWidget);
    expect(find.text('Kcal', findRichText: true), findsOneWidget);
    expect(find.text('Nấm', findRichText: true), findsNWidgets(2)); // một trong danh sách, một trong bảng
  });
}
