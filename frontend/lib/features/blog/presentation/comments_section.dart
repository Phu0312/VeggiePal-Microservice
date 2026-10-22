import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/header_actions.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/blog_models.dart';
import '../data/blog_repository.dart';

/// Bình luận của một bài viết: xem (công khai), đăng, trả lời, sửa, xoá (cần đăng nhập).
/// API: GET /comments, GET /comments/{id}/replies, POST /comments, PUT/DELETE /comments/{id}.
/// Trả lời chỉ có 1 cấp: trả lời một phản hồi sẽ gắn vào bình luận gốc của nó.
class CommentsSection extends StatefulWidget {
  final int blogId;

  /// true: mở sẵn và tải ngay 5 bình luận đầu (màn chi tiết bài viết).
  final bool initiallyOpen;
  const CommentsSection({super.key, required this.blogId, this.initiallyOpen = false});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  /// Mỗi lần tải 5 bình luận (và 5 phản hồi), bấm "Xem thêm" để tải tiếp.
  static const _pageSize = 5;

  bool _open = false; // phần bình luận được thu gọn cho tới khi người dùng bấm mở
  bool _loadedOnce = false;
  List<CommentItem> _roots = [];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = false;
  bool _loadFailed = false;
  bool _sending = false;

  final _authors = <int, PublicUser>{};
  final _replies = <int, List<CommentItem>>{}; // commentId -> phản hồi đã tải
  final _repliesHasMore = <int, bool>{};
  final _repliesPage = <int, int>{};
  final _expanded = <int>{};

  /// Bình luận vừa được chính mình gỡ: hiện dòng "Bạn đã gỡ bình luận" khoảng 10 giây rồi ẩn hẳn.
  static const _removedNoticeDuration = Duration(seconds: 10);
  final _justDeleted = <int, Timer>{};

  CommentItem? _replyTo; // bình luận gốc sẽ nhận phản hồi (BE chỉ có 1 cấp)
  CommentItem? _replyTarget; // bình luận thật sự đang được trả lời (để gắn @tên)
  CommentItem? _editing; // đang sửa bình luận này

  @override
  void initState() {
    super.initState();
    if (widget.initiallyOpen) {
      _open = true;
      _loadedOnce = true;
      _loadRoots(reset: true);
    }
  }

  /// Mở/thu gọn phần bình luận; lần mở đầu tiên mới gọi API.
  void _toggle() {
    setState(() => _open = !_open);
    if (_open && !_loadedOnce) {
      _loadedOnce = true;
      _loadRoots(reset: true);
    }
  }

  @override
  void dispose() {
    for (final t in _justDeleted.values) {
      t.cancel();
    }
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Lấy tên + ảnh của những tác giả chưa biết (GET /users/batch, tối đa 50 mỗi lần).
  Future<void> _loadAuthors(Iterable<CommentItem> items) async {
    final ids = {for (final c in items) c.authorId}.where((id) => !_authors.containsKey(id)).toList();
    if (ids.isEmpty) return;
    final repo = context.read<ProfileRepository>();
    for (var i = 0; i < ids.length; i += 50) {
      final users = await repo.publicUsers(ids.sublist(i, i + 50 > ids.length ? ids.length : i + 50));
      for (final u in users) {
        _authors[u.id] = u;
      }
    }
  }

  Future<void> _loadRoots({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _loadFailed = false;
      });
    }
    try {
      final next = reset ? 0 : _page + 1;
      final p = await context.read<BlogRepository>().comments(widget.blogId, page: next, size: _pageSize);
      await _loadAuthors(p.items);
      if (!mounted) return;
      setState(() {
        _roots = reset ? p.items : [..._roots, ...p.items];
        _page = p.page;
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (mounted) {
        if (reset) setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được bình luận');
      }
    } finally {
      if (mounted && reset) setState(() => _loading = false);
    }
  }

  Future<void> _loadReplies(CommentItem root, {bool more = false}) async {
    try {
      final next = more ? (_repliesPage[root.id] ?? 0) + 1 : 0;
      final p = await context.read<BlogRepository>().replies(root.id, page: next, size: _pageSize);
      await _loadAuthors(p.items);
      if (!mounted) return;
      setState(() {
        _replies[root.id] = more ? [...?_replies[root.id], ...p.items] : p.items;
        _repliesPage[root.id] = p.page;
        _repliesHasMore[root.id] = p.hasMore;
        _expanded.add(root.id);
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không tải được phản hồi');
    }
  }

  void _toggleReplies(CommentItem root) {
    if (_expanded.contains(root.id)) {
      setState(() => _expanded.remove(root.id));
    } else {
      _loadReplies(root);
    }
  }

  void _startReply(CommentItem c) {
    final rootId = c.parentCommentId ?? c.id;
    final root = _roots.firstWhere((r) => r.id == rootId, orElse: () => c);
    // Trả lời ai thì gắn @tên người đó ở đầu nội dung (BE không có trường tag riêng, tag là một phần chữ).
    final tag = '@${_nameOf(c.authorId)} ';
    setState(() {
      _replyTo = root;
      _replyTarget = c;
      _editing = null;
      _input.value = TextEditingValue(text: tag, selection: TextSelection.collapsed(offset: tag.length));
    });
    _focus.requestFocus();
  }

  void _startEdit(CommentItem c) {
    setState(() {
      _editing = c;
      _replyTo = null;
      _replyTarget = null;
      _input.text = c.content ?? '';
    });
    _focus.requestFocus();
  }

  void _cancelCompose() => setState(() {
        _replyTo = null;
        _replyTarget = null;
        _editing = null;
        _input.clear();
      });

  Future<void> _send() async {
    final text = _input.text.trim();
    // Chỉ có @tên mà chưa viết gì thì coi như rỗng.
    final tagOnly = _replyTarget != null && text == '@${_nameOf(_replyTarget!.authorId)}';
    if (text.isEmpty || tagOnly) {
      showSnack(context, 'Vui lòng nhập nội dung bình luận');
      return;
    }
    setState(() => _sending = true);
    final repo = context.read<BlogRepository>();
    final editing = _editing;
    final replyTo = _replyTo;
    try {
      if (editing != null) {
        await repo.editComment(editing.id, widget.blogId, text, parentCommentId: editing.parentCommentId);
      } else {
        await repo.addComment(widget.blogId, text, parentCommentId: replyTo?.id);
      }
      if (!mounted) return;
      _cancelCompose();
      FocusScope.of(context).unfocus();
      // Tải lại phần bị ảnh hưởng để thấy ngay kết quả (kể cả tên tác giả của chính mình).
      if (replyTo != null || (editing?.parentCommentId != null)) {
        final rootId = replyTo?.id ?? editing!.parentCommentId!;
        final root = _roots.firstWhere((r) => r.id == rootId, orElse: () => replyTo ?? editing!);
        await _loadReplies(root);
        await _loadRoots(reset: true); // cập nhật số phản hồi
      } else {
        await _loadRoots(reset: true);
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: editing != null ? 'Không sửa được bình luận' : 'Không gửi được bình luận');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(CommentItem c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá bình luận'),
        content: const Text('Bạn có chắc muốn xoá bình luận này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<BlogRepository>().deleteComment(c.id);
      if (!mounted) return;
      // Không tải lại danh sách ngay: giữ dòng thông báo vài giây rồi mới ẩn bình luận.
      setState(() {
        _justDeleted[c.id]?.cancel();
        _justDeleted[c.id] = Timer(_removedNoticeDuration, () => _finalizeDelete(c));
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không xoá được bình luận');
    }
  }

  /// Hết thời gian thông báo: gỡ hẳn bình luận khỏi giao diện.
  /// Bình luận gốc còn phản hồi thì giữ lại dưới dạng "đã bị xoá" để không mất chuỗi trả lời.
  void _finalizeDelete(CommentItem c) {
    if (!mounted) return;
    setState(() {
      _justDeleted.remove(c.id);
      if (c.parentCommentId == null) {
        _roots = [
          for (final r in _roots)
            if (r.id != c.id) r else if (r.replyCount > 0) r.asDeleted(),
        ];
      } else {
        final pid = c.parentCommentId!;
        _replies[pid] = [...?_replies[pid]]..removeWhere((r) => r.id == c.id);
        _roots = [
          for (final r in _roots)
            if (r.id == pid) r.withReplyCount((r.replyCount - 1).clamp(0, 1 << 30)) else r,
        ];
      }
    });
  }

  /// Bình luận đã xoá thì ẩn: gốc không còn phản hồi và mọi phản hồi đã xoá sẽ không hiển thị.
  bool _hidden(CommentItem c) {
    if (_justDeleted.containsKey(c.id)) return false; // đang hiện dòng thông báo
    final removed = c.deleted || c.content == null;
    if (!removed) return false;
    return c.parentCommentId != null || c.replyCount == 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Tiêu đề: bấm vào để mở/thu gọn bình luận; nút ở góc phải cho biết trạng thái.
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _toggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(LucideIcons.messageCircle, color: context.cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Bình luận',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            TextButton.icon(
              onPressed: _toggle,
              icon: Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 18),
              label: Text(_open ? 'Ẩn' : 'Xem'),
            ),
          ]),
        ),
      ),
      if (_open) ..._body(auth),
    ]);
  }

  List<Widget> _body(AuthController auth) {
    return [
      const SizedBox(height: 8),
      _composer(auth),
      const SizedBox(height: 8),
      if (_loading)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
      else if (_loadFailed)
        RetryView(message: 'Không tải được bình luận.', onRetry: () => _loadRoots(reset: true))
      else if (_roots.every(_hidden))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('Chưa có bình luận nào. Hãy là người đầu tiên!',
              style: TextStyle(color: context.textMuted)),
        )
      else ...[
        for (final c in _roots)
          if (!_hidden(c)) _thread(c, auth.user),
        if (_hasMore)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => _loadRoots(), child: const Text('Xem thêm bình luận')),
          ),
      ],
    ];
  }

  Widget _composer(AuthController auth) {
    if (!auth.isLoggedIn) {
      return Card(
        child: ListTile(
          leading: Icon(LucideIcons.messageCircle, color: context.cs.primary),
          title: const Text('Đăng nhập để bình luận'),
          trailing: FilledButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Đăng nhập'),
          ),
        ),
      );
    }
    final hint = _editing != null
        ? 'Sửa bình luận...'
        : _replyTo != null
            ? 'Trả lời ${_nameOf((_replyTarget ?? _replyTo!).authorId)}...'
            : 'Viết bình luận...';
    return Column(children: [
      if (_editing != null || _replyTo != null)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(_editing != null ? LucideIcons.pencil : LucideIcons.reply,
                size: 16, color: context.cs.onPrimaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  _editing != null
                      ? 'Đang sửa bình luận'
                      : 'Đang trả lời ${_nameOf((_replyTarget ?? _replyTo!).authorId)}',
                  style: TextStyle(color: context.cs.onPrimaryContainer, fontSize: 13)),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Hủy',
              icon: Icon(LucideIcons.x, size: 18, color: context.cs.onPrimaryContainer),
              onPressed: _cancelCompose,
            ),
          ]),
        ),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        UserAvatar(auth.user, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: _input,
            focusNode: _focus,
            minLines: 1,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(LucideIcons.messageSquare)),
          ),
        ),
        const SizedBox(width: 6),
        IconButton.filled(
          tooltip: 'Gửi',
          onPressed: _sending ? null : _send,
          icon: _sending
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(LucideIcons.send, size: 20),
        ),
      ]),
    ]);
  }

  String _nameOf(int userId) {
    final n = _authors[userId]?.fullName ?? '';
    return n.isEmpty ? 'người dùng #$userId' : n;
  }

  /// Tên của mọi tác giả đang hiển thị, để nhận ra phần @tên ở đầu bình luận.
  List<String> get _knownNames {
    final ids = <int>{
      for (final r in _roots) r.authorId,
      for (final list in _replies.values)
        for (final r in list) r.authorId,
    };
    return [for (final id in ids) _nameOf(id)];
  }

  Widget _thread(CommentItem root, AuthUser? me) {
    final replies = (_replies[root.id] ?? const <CommentItem>[]).where((r) => !_hidden(r)).toList();
    final open = _expanded.contains(root.id);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _CommentTile(
        comment: root,
        justDeleted: _justDeleted.containsKey(root.id),
        knownNames: _knownNames,
        author: _authors[root.authorId],
        isMine: me?.id == root.authorId,
        canReply: me != null,
        onReply: () => _startReply(root),
        onEdit: () => _startEdit(root),
        onDelete: () => _delete(root),
      ),
      if (root.replyCount > 0)
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: TextButton.icon(
            onPressed: () => _toggleReplies(root),
            icon: Icon(open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: 16),
            label: Text(open ? 'Ẩn phản hồi' : 'Xem ${root.replyCount} phản hồi'),
          ),
        ),
      if (open)
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final r in replies)
              _CommentTile(
                comment: r,
                justDeleted: _justDeleted.containsKey(r.id),
                knownNames: _knownNames,
                author: _authors[r.authorId],
                isMine: me?.id == r.authorId,
                canReply: me != null,
                onReply: () => _startReply(r),
                onEdit: () => _startEdit(r),
                onDelete: () => _delete(r),
              ),
            if (_repliesHasMore[root.id] == true)
              TextButton(
                  onPressed: () => _loadReplies(root, more: true),
                  child: const Text('Xem thêm phản hồi')),
          ]),
        ),
    ]);
  }
}

class _CommentTile extends StatelessWidget {
  final CommentItem comment;
  final bool justDeleted;
  final List<String> knownNames;
  final PublicUser? author;
  final bool isMine;
  final bool canReply;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.justDeleted,
    required this.knownNames,
    required this.author,
    required this.isMine,
    required this.canReply,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  /// Nội dung bình luận; phần @tên ở đầu (nếu khớp tên một tác giả) được tô đậm theo màu chủ đạo.
  Widget _contentWithTag(BuildContext context, String text) {
    String? tag;
    if (text.startsWith('@')) {
      final names = [...knownNames]..sort((a, b) => b.length.compareTo(a.length)); // tên dài khớp trước
      for (final n in names) {
        final t = '@$n';
        if (text.startsWith(t) && (text.length == t.length || text[t.length] == ' ' || text[t.length] == '\n')) {
          tag = t;
          break;
        }
      }
    }
    if (tag == null) return Text(text, style: const TextStyle(height: 1.4));
    return Text.rich(TextSpan(style: const TextStyle(height: 1.4), children: [
      TextSpan(
          text: tag, style: TextStyle(fontWeight: FontWeight.w700, color: context.cs.primary)),
      TextSpan(text: text.substring(tag.length)),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final name = (author?.fullName ?? '').isEmpty ? 'Người dùng #${comment.authorId}' : author!.fullName;
    final user = AuthUser(
        id: comment.authorId,
        email: '',
        fullName: author?.fullName ?? '',
        role: UserRole.user,
        avatarUrl: author?.avatarUrl);
    final deleted = comment.deleted || comment.content == null;

    if (justDeleted) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: context.cs.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(LucideIcons.trash2, size: 16, color: context.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Bạn đã gỡ bình luận này',
                style: TextStyle(fontStyle: FontStyle.italic, color: context.textMuted)),
          ),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        UserAvatar(user, radius: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (comment.createdAt != null) ...[
                const SizedBox(width: 8),
                Text(timeAgo(comment.createdAt!),
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
              ],
              if (comment.edited && !deleted)
                Text('  • đã sửa', style: TextStyle(fontSize: 12, color: context.textMuted)),
            ]),
            const SizedBox(height: 2),
            if (deleted)
              Text('Bình luận đã bị xoá',
                  style: TextStyle(height: 1.4, fontStyle: FontStyle.italic, color: context.textMuted))
            else
              _contentWithTag(context, comment.content!),
            if (!deleted)
              Row(children: [
                if (canReply)
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(0, 32)),
                    onPressed: onReply,
                    child: const Text('Trả lời'),
                  ),
                if (isMine) ...[
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(0, 32)),
                    onPressed: onEdit,
                    child: const Text('Sửa'),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 32),
                        foregroundColor: context.cs.error),
                    onPressed: onDelete,
                    child: const Text('Xoá'),
                  ),
                ],
              ]),
          ]),
        ),
      ]),
    );
  }
}
