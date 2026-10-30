import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/login_screen.dart';
import '../../profile/data/profile_models.dart';
import '../../profile/data/profile_repository.dart';
import '../data/community_models.dart';
import '../data/community_repository.dart';
import 'community_widgets.dart';

/// Mã huy hiệu BE cấp khi hoàn thành thử thách 7 ngày (BadgeCode.VEGGIE_GREEN_HEART của identity-service).
const _greenHeartCode = 'VEGGIE_GREEN_HEART';

/// Cộng đồng VeggiePal: thử thách 7 ngày sống thuần chay, chủ đề nổi bật (cuộn ngang) và bảng xếp hạng tác giả
/// (không có chính người xem) của blog-service. Kênh video đề xuất nằm ở tab Video (VideoChannelsStrip). Đọc được khi chưa đăng nhập; theo dõi tác giả và điểm danh thử thách cần
/// đăng nhập. BE chỉ trả mã tác giả nên tên và ảnh được lấy qua `/users/batch`.
/// Huy hiệu "Trái Tim Xanh Veggie" do BE tự cấp khi điểm danh đủ 7 ngày (blog-service gọi identity-service); app không
/// tự mở khoá nữa vì `POST /users/me/badges/{code}` chỉ còn dành cho ADMIN.
class CommunityScreen extends StatefulWidget {
  /// `true` khi nằm trong tab "Cộng đồng" của Trang chủ: bỏ Scaffold và AppBar riêng.
  final bool embedded;

  /// Chỉ dùng khi [embedded]: các khối nối tiếp sau phần cộng đồng (bảng tin bài viết của Trang chủ), cuộn cùng trang.
  final List<Widget> footer;

  /// Chỉ dùng khi [embedded]: điều khiển cuộn của trang, để bảng tin ở [footer] tự tải thêm khi cuộn gần cuối.
  final ScrollController? scrollController;

  /// Chỉ dùng khi [embedded]: việc làm mới thêm (tải lại bảng tin) khi kéo để làm mới.
  final Future<void> Function()? onRefresh;
  const CommunityScreen(
      {super.key, this.embedded = false, this.footer = const [], this.scrollController, this.onRefresh});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<TrendingTopic> _topics = const [];
  List<CommunityAuthor> _leaders = const [];
  ChallengeProgress? _challenge;
  final _names = <int, PublicUser>{};
  bool _loading = true;
  bool _loaded = false;
  bool _failed = false;
  bool _checkingIn = false;
  bool _badgePending = false; // đã hoàn thành thử thách nhưng BE chưa cấp được huy hiệu
  final _following = <int>{}; // mã tác giả đang gọi API theo dõi

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final repo = context.read<CommunityRepository>();
    final loggedIn = context.read<AuthController>().isLoggedIn;
    try {
      // Chủ đề và bảng xếp hạng là phần chính: lỗi thì báo cả màn hình. Thử thách chỉ là phần phụ của thành viên.
      final r = await Future.wait<Object?>([
        repo.trendingTopics(),
        repo.leaderboard(limit: 6), // lấy dư một người để vẫn đủ 5 sau khi bỏ chính mình
        if (loggedIn) repo.challenge().then<Object?>((c) => c).catchError((_) => null) else Future.value(null),
      ]);
      if (!mounted) return;
      setState(() {
        _topics = r[0] as List<TrendingTopic>;
        _leaders = r[1] as List<CommunityAuthor>;
        _challenge = r[2] as ChallengeProgress?;
        _loaded = true;
      });
      _loadNames();
      _checkBadge();
    } catch (e) {
      if (mounted) {
        setState(() => _failed = !_loaded);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được cộng đồng');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Tên và ảnh tác giả chỉ để hiển thị, lỗi được bỏ qua (dòng sẽ hiện "Thành viên #id").
  Future<void> _loadNames() async {
    final ids = {for (final a in _leaders) a.authorId}.where((id) => !_names.containsKey(id)).toList();
    if (ids.isEmpty) return;
    try {
      final users = await context.read<ProfileRepository>().publicUsers(ids);
      if (mounted) setState(() => _names.addAll({for (final u in users) u.id: u}));
    } catch (_) {}
  }

  /// Đã hoàn thành thử thách mà huy hiệu chưa có trong hồ sơ (BE cấp lỗi lần trước) thì hiện nút "Nhận huy hiệu".
  /// Chỉ là phần phụ nên lỗi mạng được bỏ qua, không nhắc nhầm.
  Future<void> _checkBadge() async {
    if (_challenge?.completed != true) {
      if (_badgePending && mounted) setState(() => _badgePending = false);
      return;
    }
    try {
      final badges = await context.read<ProfileRepository>().badges();
      final earned = badges.badges.any((b) => b.code == _greenHeartCode && b.earned);
      if (mounted) setState(() => _badgePending = !earned);
    } catch (_) {}
  }

  /// Điểm danh lại một thử thách đã hoàn thành: BE chỉ cấp lại huy hiệu (idempotent), không tính thêm ngày.
  Future<void> _claimBadge() async {
    setState(() => _checkingIn = true);
    try {
      final c = await context.read<CommunityRepository>().checkIn();
      if (!mounted) return;
      setState(() {
        _challenge = c;
        _badgePending = false;
      });
      showSnack(context, 'Đã nhận huy hiệu "${c.badgeName ?? 'Trái Tim Xanh Veggie'}"');
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Chưa nhận được huy hiệu');
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  bool _requireLogin() {
    if (context.read<AuthController>().isLoggedIn) return true;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    return false;
  }

  Future<void> _checkIn() async {
    if (!_requireLogin()) return;
    setState(() => _checkingIn = true);
    try {
      final c = await context.read<CommunityRepository>().checkIn();
      if (!mounted) return;
      setState(() => _challenge = c);
      if (c.justCompleted) {
        await showInfoDialog(context, 'Hoàn thành thử thách!',
            'Bạn đã sống thuần chay ${c.total} ngày liên tiếp và nhận huy hiệu "${c.badgeName ?? 'Trái Tim Xanh Veggie'}".');
      } else {
        showSnack(context, 'Đã điểm danh ngày ${c.days}/${c.total}');
      }
    } catch (e) {
      if (!mounted) return;
      // 3053: ngày điểm danh cuối đã được lưu nhưng BE chưa cấp được huy hiệu. Tải lại tiến độ rồi cho thử nhận lại.
      if (e is ApiException && e.code == 3053 && await _afterBadgeFailure()) return;
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không điểm danh được');
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  /// Trả `true` nếu thử thách thật sự đã hoàn thành và người dùng đã được báo; `false` thì để lỗi gốc hiện như thường.
  Future<bool> _afterBadgeFailure() async {
    try {
      final c = await context.read<CommunityRepository>().challenge();
      if (!mounted || !c.completed) return false;
      setState(() {
        _challenge = c;
        _badgePending = true;
        _checkingIn = false; // tắt vòng quay trước khi mở popup, nếu không nó quay suốt lúc popup còn mở
      });
      await showInfoDialog(context, 'Đã hoàn thành thử thách',
          'Bạn đã điểm danh đủ ${c.total} ngày, nhưng huy hiệu chưa được cấp vì hệ thống đang tạm thời gặp sự cố. '
          'Hãy bấm "Nhận huy hiệu" để thử lại sau.');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _toggleFollow(CommunityAuthor a) async {
    if (!_requireLogin()) return;
    setState(() => _following.add(a.authorId));
    try {
      final s = await context.read<CommunityRepository>().setFollow(a.authorId, !a.following);
      if (!mounted) return;
      CommunityAuthor update(CommunityAuthor x) =>
          x.authorId == s.authorId ? x.withFollow(following: s.following, followers: s.followers) : x;
      setState(() {
        _leaders = [for (final x in _leaders) update(x)];
      });
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không cập nhật được theo dõi');
    } finally {
      if (mounted) setState(() => _following.remove(a.authorId));
    }
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
      );

  @override
  Widget build(BuildContext context) {
    final selfId = context.watch<AuthController>().user?.id;
    // Bảng xếp hạng không hiện chính người xem.
    final leaders = _leaders.where((a) => a.authorId != selfId).take(5).toList();
    final sections = <Widget>[
      if (_loaded) ...[
        _heading('Thử thách 7 ngày sống thuần chay'),
        _ChallengeCard(
          progress: _challenge,
          loggedIn: context.watch<AuthController>().isLoggedIn,
          busy: _checkingIn,
          badgePending: _badgePending,
          onCheckIn: _checkIn,
          onClaimBadge: _claimBadge,
        ),
        if (_topics.isNotEmpty) ...[
          _heading('Chủ đề nổi bật'),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _topics.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Chip(label: Text('${_topics[i].name} • ${_topics[i].count}')),
            ),
          ),
        ],
        _heading('Bảng xếp hạng tác giả'),
        if (leaders.isEmpty)
          Text('Chưa có tác giả nào.', style: TextStyle(color: context.textMuted))
        else
          for (var i = 0; i < leaders.length; i++)
            AuthorTile(
              rank: i + 1,
              author: leaders[i],
              user: _names[leaders[i].authorId],
              isSelf: false,
              busy: _following.contains(leaders[i].authorId),
              subtitle: '${leaders[i].articles} bài • ${leaders[i].videos} video • ${leaders[i].likes} lượt thích',
              onFollow: () => _toggleFollow(leaders[i]),
            ),
      ] else if (!widget.embedded)
        _loading
            ? const Center(child: CircularProgressIndicator())
            : RetryView(message: _failed ? 'Không tải được cộng đồng.' : 'Không có dữ liệu.', onRetry: _load)
      else if (_loading)
        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
      else
        // Trong Trang chủ, lỗi cộng đồng không được che bảng tin bên dưới: chỉ hiện một dòng thử lại.
        Card(
          child: ListTile(
            title: Text(_failed ? 'Không tải được cộng đồng.' : 'Không có dữ liệu cộng đồng.'),
            trailing: TextButton(onPressed: _load, child: const Text('Thử lại')),
          ),
        ),
    ];
    final Widget body;
    if (!widget.embedded && !_loaded) {
      body = sections.single;
    } else {
      body = RefreshIndicator(
        onRefresh: () => Future.wait([_load(), widget.onRefresh?.call() ?? Future<void>.value()]),
        child: ListView(
          controller: widget.embedded ? widget.scrollController : null,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 8, 16, widget.embedded ? 100 : 32),
          children: [...sections, if (widget.embedded) ...widget.footer],
        ),
      );
    }
    if (widget.embedded) return body;
    return Scaffold(appBar: AppBar(title: const Text('Cộng đồng')), body: body);
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeProgress? progress;
  final bool loggedIn;
  final bool busy;
  final bool badgePending;
  final VoidCallback onCheckIn;
  final VoidCallback onClaimBadge;
  const _ChallengeCard({
    required this.progress,
    required this.loggedIn,
    required this.busy,
    required this.badgePending,
    required this.onCheckIn,
    required this.onClaimBadge,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress ?? const ChallengeProgress();
    final String message;
    if (!loggedIn) {
      message = 'Đăng nhập để tham gia và nhận huy hiệu "Trái Tim Xanh Veggie".';
    } else if (p.completed && badgePending) {
      message = 'Bạn đã hoàn thành thử thách nhưng huy hiệu chưa được cấp do hệ thống tạm thời gặp sự cố. '
          'Bấm "Nhận huy hiệu" để thử lại.';
    } else if (p.completed) {
      message = 'Bạn đã hoàn thành thử thách và nhận huy hiệu ${p.badgeName ?? 'Trái Tim Xanh Veggie'}.';
    } else if (p.broken) {
      message = 'Chuỗi ngày đã bị gián đoạn. Điểm danh hôm nay để bắt đầu lại từ ngày 1.';
    } else if (p.checkedToday) {
      message = 'Hôm nay bạn đã điểm danh. Hẹn gặp lại ngày mai!';
    } else if (p.days == 0) {
      message = 'Ăn thuần chay mỗi ngày và điểm danh ${p.total} ngày liên tiếp.';
    } else {
      message = 'Hôm nay bạn chưa điểm danh. Giữ chuỗi nhé!';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            for (var i = 0; i < p.total; i++)
              CircleAvatar(
                radius: 16,
                backgroundColor: i < p.days ? context.cs.primary : context.cs.surfaceContainerHighest,
                child: i < p.days
                    ? Icon(LucideIcons.check, size: 16, color: context.cs.onPrimary)
                    : Text('${i + 1}', style: TextStyle(fontSize: 12, color: context.textMuted)),
              ),
          ]),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: context.textMuted, fontSize: 13)),
          if (!loggedIn || p.canCheckIn) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: busy ? null : onCheckIn,
              icon: busy
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.calendarCheck),
              label: Text(loggedIn ? 'Điểm danh hôm nay' : 'Đăng nhập để tham gia'),
            ),
          ] else if (p.completed && badgePending) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: busy ? null : onClaimBadge,
              icon: busy
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.award),
              label: const Text('Nhận huy hiệu'),
            ),
          ],
        ]),
      ),
    );
  }
}
