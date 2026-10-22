import '../../home/data/home_models.dart';

/// Bình luận (blog-service: CommentResponse).
class CommentItem {
  final int id;
  final int authorId;
  final int? parentCommentId;
  final String? content; // null khi bình luận đã bị xoá (dòng được giữ lại để không mất chuỗi trả lời)
  final bool deleted;
  final int replyCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CommentItem({
    required this.id,
    required this.authorId,
    this.parentCommentId,
    this.content,
    this.deleted = false,
    this.replyCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CommentItem.fromJson(Map<String, dynamic> j) => CommentItem(
        id: (j['id'] as num).toInt(),
        authorId: (j['authorId'] as num).toInt(),
        parentCommentId: (j['parentCommentId'] as num?)?.toInt(),
        content: j['content'] as String?,
        deleted: j['deleted'] == true,
        replyCount: (j['replyCount'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
        updatedAt: j['updatedAt'] == null ? null : DateTime.tryParse('${j['updatedAt']}'),
      );

  CommentItem withReplyCount(int n) => CommentItem(
        id: id,
        authorId: authorId,
        parentCommentId: parentCommentId,
        content: content,
        deleted: deleted,
        replyCount: n,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Bản đã xoá: nội dung bị gỡ (giống cách BE trả về), giữ lại số phản hồi.
  CommentItem asDeleted() => CommentItem(
        id: id,
        authorId: authorId,
        parentCommentId: parentCommentId,
        content: null,
        deleted: true,
        replyCount: replyCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Đã chỉnh sửa sau khi đăng (cách nhau quá vài giây).
  bool get edited =>
      createdAt != null && updatedAt != null && updatedAt!.difference(createdAt!).inSeconds > 5;
}

/// Một trang kết quả (PageResponse của backend).
class PageData<T> {
  final List<T> items;
  final int page;
  final int totalPages;
  final int totalElements;
  const PageData(this.items, this.page, this.totalPages, [this.totalElements = 0]);

  bool get hasMore => page + 1 < totalPages;
}

/// Phiếu bầu của tôi và điểm hiện tại của một bài viết (VoteResponse).
class VoteInfo {
  final int blogId;
  final int? myVote; // 1, -1 hoặc null (chưa bầu)
  final int? voteScore; // null khi lấy theo GET /blogs/me/votes
  const VoteInfo(this.blogId, this.myVote, this.voteScore);

  factory VoteInfo.fromJson(Map<String, dynamic> j) => VoteInfo(
        (j['blogId'] as num).toInt(),
        (j['myVote'] as num?)?.toInt(),
        (j['voteScore'] as num?)?.toInt(),
      );
}

/// Danh mục dạng cây (blog-service: CategoryResponse, sâu 2 cấp).
class CategoryNode {
  final int id;
  final int? parentId;
  final String type; // FOOD_TYPE | RECIPE_TYPE
  final String name;
  final int displayOrder;
  final bool active;
  final List<CategoryNode> children;

  const CategoryNode({
    required this.id,
    this.parentId,
    required this.type,
    required this.name,
    this.displayOrder = 0,
    this.active = true,
    this.children = const [],
  });

  factory CategoryNode.fromJson(Map<String, dynamic> j) => CategoryNode(
        id: (j['id'] as num).toInt(),
        parentId: (j['parentId'] as num?)?.toInt(),
        type: '${j['type'] ?? 'FOOD_TYPE'}',
        name: '${j['name']}',
        displayOrder: (j['displayOrder'] as num?)?.toInt() ?? 0,
        active: j['active'] != false,
        children: [
          for (final c in (j['children'] as List? ?? const []))
            CategoryNode.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
      );
}

/// Kết quả hiển thị cho người dùng sau khi lưu/đăng/gửi duyệt một bài viết, theo trạng thái BE trả về.
/// [needsDialog] = true khi cần popup (bài chờ duyệt/bị từ chối kèm lý do), ngược lại chỉ cần snack.
({String title, String message, bool needsDialog}) blogOutcome(BlogItem b) {
  final reason = (b.moderationReason ?? '').trim();
  switch (b.status) {
    case 'PUBLISHED':
      return (title: 'Đã đăng', message: 'Bài viết "${b.title}" đã được đăng.', needsDialog: false);
    case 'PENDING':
      return (
        title: 'Chờ kiểm duyệt',
        message: 'Bài viết đang chờ quản trị viên kiểm duyệt trước khi hiển thị công khai.'
            '${reason.isEmpty ? '' : '\n\nLý do: $reason'}',
        needsDialog: true,
      );
    case 'REJECTED':
      return (
        title: 'Bài viết không được duyệt',
        message: 'Nội dung vi phạm quy định cộng đồng.${reason.isEmpty ? '' : '\n\nLý do: $reason'}',
        needsDialog: true,
      );
    default:
      return (title: 'Đã lưu', message: 'Đã lưu bản nháp.', needsDialog: false);
  }
}
