import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/core/utils/moderation.dart';
import 'package:VeggiePal/features/blog/data/blog_models.dart';
import 'package:VeggiePal/features/home/data/home_models.dart';
import 'package:VeggiePal/features/video/data/video_models.dart';

/// Hai câu lý do tiếng Anh mà BE tự điền khi AI kiểm duyệt không dùng được.
const _blogServiceFallback = 'AI moderation temporarily unavailable; pending manual review';
const _aiServiceFallback = 'AI moderation temporarily unavailable; queued for manual review';

void main() {
  group('moderationReasonVi', () {
    test('dịch cả hai câu dự phòng của BE, kể cả khi thừa khoảng trắng hoặc khác hoa thường', () {
      expect(moderationReasonVi(_blogServiceFallback), aiUnavailableReasonVi);
      expect(moderationReasonVi(_aiServiceFallback), aiUnavailableReasonVi);
      expect(moderationReasonVi('  AI Moderation temporarily unavailable; pending manual review '), aiUnavailableReasonVi);
    });

    test('lý do do AI viết giữ nguyên; rỗng thì vẫn rỗng', () {
      expect(moderationReasonVi('Có nội dung quảng cáo'), 'Có nội dung quảng cáo');
      expect(moderationReasonVi(''), '');
      expect(moderationReasonVi('   '), '');
    });

    test('nhóm ai_fallback có nhãn tiếng Việt, nhóm khác giữ nguyên', () {
      expect(moderationCategoryVi('ai_fallback'), isNot('ai_fallback'));
      expect(moderationCategoryVi('spam'), 'spam');
    });
  });

  group('thông báo sau khi gửi duyệt khi AI kiểm duyệt gián đoạn', () {
    test('bài viết: trạng thái chờ duyệt, lý do hiển thị bằng tiếng Việt', () {
      final out = blogOutcome(BlogItem.fromJson(
          {'id': 1, 'title': 'Cà ri chay', 'status': 'PENDING', 'moderationReason': _blogServiceFallback}));
      expect(out.title, 'Chờ kiểm duyệt');
      expect(out.needsDialog, isTrue);
      expect(out.message, contains(aiUnavailableReasonVi));
      expect(out.message, isNot(contains('temporarily unavailable')));
    });

    test('video: trạng thái chờ duyệt, lý do hiển thị bằng tiếng Việt', () {
      final out = videoOutcome(Video.fromJson({
        'id': 5,
        'authorId': 9,
        'categoryId': 3,
        'title': 'Phở chay',
        'sourceType': 'YOUTUBE',
        'videoUrl': 'https://www.youtube.com/embed/dQw4w9WgXcQ',
        'status': 'PENDING',
        'moderationReason': _aiServiceFallback,
      }));
      expect(out.title, 'Chờ kiểm duyệt');
      expect(out.needsDialog, isTrue);
      expect(out.message, contains(aiUnavailableReasonVi));
    });

    test('bài chờ duyệt không có lý do thì không in dòng "Lý do"', () {
      final out = blogOutcome(BlogItem.fromJson({'id': 1, 'title': 'x', 'status': 'PENDING'}));
      expect(out.message, isNot(contains('Lý do')));
    });
  });
}
