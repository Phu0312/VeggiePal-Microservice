import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_type.dart';
import '../../home/data/home_models.dart';
import 'blog_models.dart';

/// blog-service: quản lý bài viết của tôi, vote, bình luận, bài liên quan và danh mục (admin).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class BlogRepository {
  final ApiClient _api;
  BlogRepository(this._api);

  static const maxThumbnailBytes = 5 * 1024 * 1024; // backend giới hạn 5MB

  BlogItem _blog(dynamic r) => BlogItem.fromJson(Map<String, dynamic>.from(r as Map));

  // ---------------- bài viết ----------------

  // GET /blogs/{id}/related (công khai)
  Future<List<BlogItem>> related(int id) async {
    final r = await _api.get(Endpoints.blogRelated(id));
    return asList(r).map(_blog).toList();
  }

  // PUT /blogs/{id} {title, content, categoryId}; bài đã qua kiểm duyệt sẽ bị kiểm duyệt lại.
  Future<BlogItem> updateBlog(int id,
      {required String title, required String content, required int categoryId}) async {
    final r = await _api.put(Endpoints.blogById(id),
        body: {'title': title, 'content': content, 'categoryId': categoryId});
    return _blog(r);
  }

  // DELETE /blogs/{id}
  Future<void> deleteBlog(int id) async {
    await _api.delete(Endpoints.blogById(id));
  }

  // POST /blogs/{id}/submit: gửi bản nháp đi kiểm duyệt.
  Future<BlogItem> submitBlog(int id) async {
    final r = await _api.post(Endpoints.blogSubmit(id));
    return _blog(r);
  }

  // POST /blogs/{id}/thumbnail (multipart `file`; JPEG/PNG/WEBP, tối đa 5MB)
  Future<BlogItem> uploadThumbnail(int id, Uint8List bytes) async {
    final type = sniffImageType(bytes);
    if (type == null) throw ApiException('Ảnh bìa phải là JPEG, PNG hoặc WEBP.');
    if (bytes.length > maxThumbnailBytes) {
      throw ApiException('Ảnh bìa không được vượt quá 5MB.');
    }
    final r = await _api.post(Endpoints.blogThumbnail(id),
        body: FormData.fromMap({'file': imagePart(bytes, type)}));
    return _blog(r);
  }

  // ---------------- vote ----------------

  // POST /blogs/{id}/vote {value: 1 | -1}; bầu cùng giá trị lần nữa = rút lại phiếu.
  Future<VoteInfo> vote(int id, int value) async {
    final r = await _api.post(Endpoints.blogVote(id), body: {'value': value});
    return VoteInfo.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // DELETE /blogs/{id}/vote
  Future<VoteInfo> removeVote(int id) async {
    final r = await _api.delete(Endpoints.blogVote(id));
    return VoteInfo.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /blogs/me/votes?blogIds=1&blogIds=2 (tối đa 100) -> phiếu bầu của tôi cho từng bài.
  Future<List<VoteInfo>> myVotes(List<int> blogIds) async {
    if (blogIds.isEmpty) return const [];
    final r = await _api.get(Endpoints.myBlogVotes, query: {'blogIds': blogIds});
    return asList(r)
        .map((e) => VoteInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // ---------------- bình luận ----------------

  PageData<CommentItem> _commentPage(dynamic r) {
    final m = Map<String, dynamic>.from(r as Map);
    return PageData(
      asList(r)
          .map((e) => CommentItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      (m['page'] as num?)?.toInt() ?? 0,
      (m['totalPages'] as num?)?.toInt() ?? 1,
      (m['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  // Tổng số bình luận gốc của một bài: gọi trang 1 phần tử rồi đọc totalElements (BE không có API đếm riêng).
  Future<int> commentCount(int blogId) async {
    final p = await comments(blogId, page: 0, size: 1);
    return p.totalElements;
  }

  // GET /comments?targetType=BLOG&targetId=&page=&size= (công khai) -> bình luận gốc
  Future<PageData<CommentItem>> comments(int blogId, {int page = 0, int size = 20}) async {
    final r = await _api.get(Endpoints.comments,
        query: {'targetType': 'BLOG', 'targetId': blogId, 'page': page, 'size': size});
    return _commentPage(r);
  }

  // GET /comments/{id}/replies?page=&size= (công khai)
  Future<PageData<CommentItem>> replies(int commentId, {int page = 0, int size = 20}) async {
    final r = await _api.get(Endpoints.commentReplies(commentId),
        query: {'page': page, 'size': size});
    return _commentPage(r);
  }

  // POST /comments {targetType, targetId, parentCommentId?, content}
  Future<CommentItem> addComment(int blogId, String content, {int? parentCommentId}) async {
    final r = await _api.post(Endpoints.comments, body: {
      'targetType': 'BLOG',
      'targetId': blogId,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'content': content,
    });
    return CommentItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PUT /comments/{id}: BE vẫn yêu cầu gửi lại targetType/targetId.
  Future<CommentItem> editComment(int commentId, int blogId, String content,
      {int? parentCommentId}) async {
    final r = await _api.put(Endpoints.commentById(commentId), body: {
      'targetType': 'BLOG',
      'targetId': blogId,
      if (parentCommentId != null) 'parentCommentId': parentCommentId,
      'content': content,
    });
    return CommentItem.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // DELETE /comments/{id} (xoá mềm: dòng được giữ lại, nội dung thành null)
  Future<void> deleteComment(int commentId) async {
    await _api.delete(Endpoints.commentById(commentId));
  }

  // ---------------- danh mục (admin) ----------------

  // GET /categories?type=&activeOnly= -> cây danh mục. activeOnly=false để admin thấy cả mục đã ẩn.
  Future<List<CategoryNode>> categoryTree({String? type, bool activeOnly = true}) async {
    final r = await _api.get(Endpoints.categories, query: {
      if (type != null) 'type': type,
      'activeOnly': activeOnly,
    });
    return asList(r)
        .map((e) => CategoryNode.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  // GET /categories/{id}
  Future<CategoryNode> category(int id) async {
    final r = await _api.get(Endpoints.categoryById(id));
    return CategoryNode.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // POST /categories (admin). Danh mục gốc cần type; danh mục con thừa hưởng type của cha.
  Future<CategoryNode> createCategory(
      {required String name,
      String? type,
      int? parentId,
      int displayOrder = 0,
      bool active = true}) async {
    final r = await _api.post(Endpoints.categories, body: {
      'name': name,
      if (parentId == null) 'type': type,
      if (parentId != null) 'parentId': parentId,
      'displayOrder': displayOrder,
      'active': active,
    });
    return CategoryNode.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PUT /categories/{id} (admin): đổi tên, thứ tự hiển thị, ẩn/hiện.
  Future<CategoryNode> updateCategory(int id,
      {required String name, String? type, int displayOrder = 0, bool active = true}) async {
    final r = await _api.put(Endpoints.categoryById(id), body: {
      'name': name,
      if (type != null) 'type': type,
      'displayOrder': displayOrder,
      'active': active,
    });
    return CategoryNode.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // DELETE /categories/{id} (admin): chỉ xoá được danh mục chưa có nội dung nào dùng.
  Future<void> deleteCategory(int id) async {
    await _api.delete(Endpoints.categoryById(id));
  }
}
