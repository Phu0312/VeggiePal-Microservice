import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../network/api_client.dart';
import '../../features/blog/data/blog_models.dart';
import 'common_widgets.dart';

/// Danh sách phân trang dùng chung: kéo xuống cuối thì tải thêm, kéo từ trên xuống để tải lại.
/// Giữ khoá `GlobalKey<PagedListViewState<T>>` để gọi `reload()` khi bộ lọc đổi, hoặc cập nhật từng mục.
class PagedListView<T> extends StatefulWidget {
  final Future<PageData<T>> Function(int page) load;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;
  final String errorTitle;
  final EdgeInsets padding;
  final double spacing;

  const PagedListView({
    super.key,
    required this.load,
    required this.itemBuilder,
    required this.emptyText,
    this.errorTitle = 'Không tải được dữ liệu',
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.spacing = 8,
  });

  @override
  State<PagedListView<T>> createState() => PagedListViewState<T>();
}

class PagedListViewState<T> extends State<PagedListView<T>> {
  final _scroll = ScrollController();
  final _items = <T>[];
  int _page = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  int _generation = 0; // bỏ kết quả của lần tải cũ khi đã bắt đầu lần tải mới

  /// Các mục đang hiển thị (chỉ đọc).
  List<T> get items => List.unmodifiable(_items);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 300) _loadMore();
    });
    reload();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Tải lại từ trang đầu. [silent] = không hiện vòng quay và không báo lỗi (dùng cho tự làm mới định kỳ).
  Future<void> reload({bool silent = false}) async {
    final gen = ++_generation;
    if (!silent) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    }
    try {
      final p = await widget.load(0);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items
          ..clear()
          ..addAll(p.items);
        _page = p.page;
        _hasMore = p.hasMore;
        _failed = false;
      });
    } catch (e) {
      if (!mounted || gen != _generation || silent) return;
      setState(() => _failed = true);
      showErrorDialog(context, errorMessage(e), title: widget.errorTitle);
    } finally {
      if (mounted && gen == _generation && !silent) setState(() => _loading = false);
    }
  }

  /// Thay mục thoả [test] bằng [replacement] (vd cập nhật trạng thái một lượt xử lý) mà không tải lại cả danh sách.
  void replaceWhere(bool Function(T) test, T replacement) {
    final i = _items.indexWhere(test);
    if (i < 0) return;
    setState(() => _items[i] = replacement);
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final gen = _generation;
    setState(() => _loadingMore = true);
    try {
      final p = await widget.load(_page + 1);
      if (!mounted || gen != _generation) return;
      setState(() {
        _items.addAll(p.items);
        _page = p.page;
        _hasMore = p.hasMore;
      });
    } catch (e) {
      if (mounted && gen == _generation) showSnack(context, errorMessage(e));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) return RetryView(onRetry: reload);
    return RefreshIndicator(
      onRefresh: reload,
      child: _items.isEmpty
          ? ListView(children: [
              Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                    child: Text(widget.emptyText,
                        textAlign: TextAlign.center, style: TextStyle(color: context.textMuted))),
              ),
            ])
          : ListView.separated(
              controller: _scroll,
              padding: widget.padding,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _items.length + (_loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(height: widget.spacing),
              itemBuilder: (context, i) {
                if (i == _items.length) {
                  return const Padding(
                      padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
                }
                return widget.itemBuilder(context, _items[i]);
              },
            ),
    );
  }
}
