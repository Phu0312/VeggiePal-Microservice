import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../menu_planner/data/health_sync.dart';
import '../../menu_planner/data/menu_models.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';

/// Lịch sử chiều cao/cân nặng/BMI. Danh sách: GET /nutrition/me/health-records;
/// thêm mới: POST; sửa một bản ghi: PUT /nutrition/me/health-records/{id}.
class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<HealthRecord> _records = [];
  bool _loading = true;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final r = await context.read<ProfileRepository>().healthRecords();
      if (mounted) setState(() => _records = r);
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được lịch sử sức khỏe');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([HealthRecord? record]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _RecordForm(record),
      ),
    );
    if (saved == true) {
      if (mounted) context.read<HealthSync>().changed(); // tab Thực đơn nạp lại chỉ số mới nhất
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử sức khỏe')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'health-add',
        onPressed: () => _openEditor(),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Thêm chỉ số'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? RetryView(onRetry: _load)
              : _records.isEmpty
                  ? Center(
                      child: Text('Chưa có chỉ số nào. Bấm "Thêm chỉ số" để bắt đầu.',
                          style: TextStyle(color: context.textMuted)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: _records.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _RecordCard(_records[i], onEdit: () => _openEditor(_records[i])),
                      ),
                    ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final HealthRecord r;
  final VoidCallback onEdit;
  const _RecordCard(this.r, {required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final category = HealthInfo(r.heightCm, r.weightKg, r.bmi).category;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Column(children: [
            Text(r.bmi.toStringAsFixed(1),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: context.cs.primary)),
            Text('BMI', style: TextStyle(fontSize: 12, color: context.textMuted)),
          ]),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${r.heightCm} cm  •  ${r.weightKg} kg'),
              if (r.recordedAt != null)
                Text(fmtDateTime(r.recordedAt!),
                    style: TextStyle(fontSize: 12, color: context.textMuted)),
            ]),
          ),
          IconButton(
              tooltip: 'Sửa', onPressed: onEdit, icon: const Icon(LucideIcons.pencil, size: 20)),
        ]),
      ),
    );
  }
}

/// Form thêm/sửa một bản ghi (record == null -> thêm mới).
class _RecordForm extends StatefulWidget {
  final HealthRecord? record;
  const _RecordForm(this.record);

  @override
  State<_RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<_RecordForm> {
  final _form = GlobalKey<FormState>();
  late final _height =
      TextEditingController(text: widget.record == null ? '' : '${widget.record!.heightCm}');
  late final _weight =
      TextEditingController(text: widget.record == null ? '' : '${widget.record!.weightKg}');
  bool _busy = false;

  @override
  void dispose() {
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final repo = context.read<ProfileRepository>();
    final h = double.parse(_height.text.replaceAll(',', '.'));
    final w = double.parse(_weight.text.replaceAll(',', '.'));
    try {
      if (widget.record == null) {
        await repo.createHealthRecord(h, w);
      } else {
        await repo.updateHealthRecord(widget.record!.id, h, w);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không lưu được chỉ số');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _range(String? v, double min, double max, String name) {
    final d = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (d == null) return 'Vui lòng nhập $name';
    if (d < min || d > max) return '$name phải từ ${min.toInt()} đến ${max.toInt()}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.record == null ? 'Thêm chỉ số mới' : 'Sửa chỉ số',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _height,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Chiều cao (cm)',
                hintText: 'Từ 50 đến 250, tối đa 1 số lẻ',
                prefixIcon: Icon(LucideIcons.ruler)),
            validator: (v) => _range(v, 50, 250, 'Chiều cao'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Cân nặng (kg)',
                hintText: 'Từ 20 đến 300, tối đa 1 số lẻ',
                prefixIcon: Icon(LucideIcons.weight)),
            validator: (v) => _range(v, 20, 300, 'Cân nặng'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu'),
            ),
          ),
        ]),
      ),
    );
  }
}
