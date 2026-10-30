import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Biểu tượng của từng huy hiệu theo tên `icon` mà BE trả về.
IconData badgeIcon(String name) => switch (name) {
      'sprout' => LucideIcons.sprout,
      'check' => LucideIcons.badgeCheck,
      'user' => LucideIcons.userCheck,
      'calendar' => LucideIcons.calendarCheck,
      'droplets' => LucideIcons.droplets,
      'sparkles' => LucideIcons.sparkles,
      _ => LucideIcons.award,
    };

/// Huy hiệu xanh (GET /users/me/badges): đã đạt bao nhiêu trên tổng số, mỗi huy hiệu kèm điều kiện và ngày đạt.
class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  BadgeCollection? _data;
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
    try {
      final d = await context.read<ProfileRepository>().badges();
      if (mounted) setState(() => _data = d);
    } catch (e) {
      if (mounted) {
        setState(() => _failed = _data == null);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được huy hiệu');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Huy hiệu xanh')),
      body: d == null
          ? (_loading
              ? const Center(child: CircularProgressIndicator())
              : RetryView(message: _failed ? 'Không tải được huy hiệu.' : 'Không có dữ liệu.', onRetry: _load))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Icon(LucideIcons.trophy, size: 36, color: context.cs.primary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Đã đạt ${d.earnedCount}/${d.totalCount} huy hiệu',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                                value: d.totalCount == 0 ? 0 : d.earnedCount / d.totalCount, minHeight: 8),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                for (final b in d.badges)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: b.earned ? context.cs.primaryContainer : context.cs.surfaceContainerHighest,
                        child: Icon(badgeIcon(b.icon), color: b.earned ? context.cs.onPrimaryContainer : context.textMuted),
                      ),
                      title: Text(b.title,
                          style: TextStyle(fontWeight: FontWeight.w700, color: b.earned ? null : context.textMuted)),
                      subtitle: Text(b.earned && b.earnedAt != null
                          ? '${b.description}\nĐạt ngày ${fmtDate(b.earnedAt!.toLocal())}'
                          : b.description),
                      isThreeLine: b.earned && b.earnedAt != null,
                      trailing: Icon(b.earned ? LucideIcons.circleCheck : LucideIcons.lock,
                          color: b.earned ? context.cs.primary : context.textMuted, size: 20),
                    ),
                  ),
              ]),
            ),
    );
  }
}
