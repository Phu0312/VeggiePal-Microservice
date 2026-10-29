import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/paged_list_view.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

/// Giám sát AI (admin, ai-service): "Tổng quan" (số lượt gọi, lỗi, token, độ trễ trong N ngày gần nhất, model
/// đang cấu hình và giới hạn sử dụng) và "Nhật ký" (từng lượt gọi AI, lọc theo tác vụ và trạng thái).
class AdminAiTab extends StatefulWidget {
  const AdminAiTab({super.key});

  @override
  State<AdminAiTab> createState() => _AdminAiTabState();
}

class _AdminAiTabState extends State<AdminAiTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _showLogs = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: FullWidthSegmented<bool>(
          options: const [SegmentOption(false, 'Tổng quan'), SegmentOption(true, 'Nhật ký')],
          selected: _showLogs,
          onChanged: (v) => setState(() => _showLogs = v),
        ),
      ),
      // IndexedStack giữ bộ lọc và vị trí cuộn của từng phần khi chuyển qua lại.
      Expanded(
        child: IndexedStack(index: _showLogs ? 1 : 0, children: const [_AiOverview(), _AiLogs()]),
      ),
    ]);
  }
}

class _AiOverview extends StatefulWidget {
  const _AiOverview();

  @override
  State<_AiOverview> createState() => _AiOverviewState();
}

class _AiOverviewState extends State<_AiOverview> {
  static const _periods = [7, 30, 90]; // backend giới hạn 1-90 ngày

  int _days = 7;
  UsageSummary? _summary;
  Map<String, String> _models = {};
  Map<String, num> _limits = {};
  bool _loading = true;
  bool _failed = false;

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
    final repo = context.read<AdminRepository>();
    try {
      final r = await Future.wait<Object>([repo.usageSummary(_days), repo.aiModels(), repo.aiLimits()]);
      if (!mounted) return;
      setState(() {
        _summary = r[0] as UsageSummary;
        _models = r[1] as Map<String, String>;
        _limits = r[2] as Map<String, num>;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _failed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được số liệu AI');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _tile(String label, String value, {Color? color}) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(
              child: Text(value,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color ?? context.cs.primary)),
            ),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: context.textMuted)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = _summary;
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final d in _periods) ...[
              ChoiceChip(
                label: Text('$d ngày gần nhất'),
                selected: _days == d,
                onSelected: (_) {
                  setState(() => _days = d);
                  _load();
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_failed || s == null)
                ? RetryView(onRetry: _load)
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.1,
                        children: [
                          _tile('Lượt gọi AI', formatCount(s.requests)),
                          _tile('Lượt lỗi', formatCount(s.failedRequests),
                              color: s.failedRequests > 0 ? context.cs.error : null),
                          _tile('Tổng token', formatCount(s.totalTokens)),
                          _tile('Độ trễ trung bình', '${s.averageLatencyMs.round()} ms'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                          'Token vào ${formatCount(s.promptTokens)} • token ra ${formatCount(s.completionTokens)}'
                          '${s.requests == 0 ? '' : ' • tỉ lệ lỗi ${(s.failureRate * 100).toStringAsFixed(1)}%'}',
                          style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                      const SectionHeader('Model đang dùng'),
                      for (final e in aiModelLabels.entries)
                        if (_models.containsKey(e.key))
                          ListTile(dense: true, title: Text(e.value), trailing: Text(_models[e.key]!)),
                      const SectionHeader('Giới hạn sử dụng'),
                      for (final e in aiLimitLabels.entries)
                        if (_limits.containsKey(e.key))
                          ListTile(
                              dense: true,
                              title: Text(e.value),
                              trailing: Text(formatCount(_limits[e.key]!),
                                  style: const TextStyle(fontWeight: FontWeight.w700))),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                            'Lượt chat của thành viên thực tế theo gói đăng ký (FREE / PLUS / PRO), không theo giá trị mặc định ở trên.',
                            style: TextStyle(fontSize: 12, color: context.textMuted)),
                      ),
                    ]),
                  ),
      ),
    ]);
  }
}

class _AiLogs extends StatefulWidget {
  const _AiLogs();

  @override
  State<_AiLogs> createState() => _AiLogsState();
}

class _AiLogsState extends State<_AiLogs> {
  static const _statuses = <String?, String>{null: 'Mọi trạng thái', 'SUCCESS': 'Thành công', 'FAILED': 'Lỗi'};

  final _list = GlobalKey<PagedListViewState<UsageLog>>();
  String? _feature;
  String? _status;

  Widget _chips(Map<String?, String> options, String? selected, void Function(String?) onTap) => SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            for (final e in options.entries) ...[
              ChoiceChip(
                  label: Text(e.value), selected: selected == e.key, onSelected: (_) => onTap(e.key)),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AdminRepository>();
    return Column(children: [
      const SizedBox(height: 4),
      _chips({null: 'Mọi tác vụ', for (final e in aiFeatureLabels.entries) e.key: e.value}, _feature, (v) {
        setState(() => _feature = v);
        _list.currentState?.reload();
      }),
      _chips(_statuses, _status, (v) {
        setState(() => _status = v);
        _list.currentState?.reload();
      }),
      Expanded(
        child: PagedListView<UsageLog>(
          key: _list,
          errorTitle: 'Không tải được nhật ký AI',
          load: (page) => repo.usageLogs(feature: _feature, status: _status, page: page),
          emptyText: 'Chưa có lượt gọi AI nào trong bộ lọc này.',
          itemBuilder: (context, l) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(aiFeatureLabel(l.feature), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  StatusPill(l.failed ? 'Lỗi' : 'Thành công', l.failed ? context.cs.error : Colors.green),
                  const Spacer(),
                  if (l.createdAt != null)
                    Text(fmtDateTime(l.createdAt!), style: TextStyle(fontSize: 12, color: context.textMuted)),
                ]),
                const SizedBox(height: 4),
                Text(
                    '${l.model}  •  ${l.userId == null ? 'Khách' : 'Người dùng #${l.userId}'}\n'
                    '${formatCount(l.promptTokens)} + ${formatCount(l.completionTokens)} token  •  ${l.latencyMs} ms',
                    style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                if (l.failed && (l.errorMessage ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(l.errorMessage!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: context.cs.error)),
                  ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }
}
