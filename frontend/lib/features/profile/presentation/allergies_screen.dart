import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/profile_models.dart';
import '../data/profile_repository.dart';
import 'allergen_chips.dart';

/// Chọn các thực phẩm bạn dị ứng. Danh mục lấy từ GET /nutrition/allergens, lựa chọn hiện tại từ
/// GET /nutrition/me/allergies và lưu bằng PUT /nutrition/me/allergies (thay thế toàn bộ danh sách).
class AllergiesScreen extends StatefulWidget {
  const AllergiesScreen({super.key});

  @override
  State<AllergiesScreen> createState() => _AllergiesScreenState();
}

class _AllergiesScreenState extends State<AllergiesScreen> {
  List<Allergen> _catalog = [];
  final _selected = <int>{};
  bool _loading = true;
  bool _loadFailed = false;
  bool _saving = false;

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
      final repo = context.read<ProfileRepository>();
      final r = await Future.wait([repo.allergens(), repo.myAllergies()]);
      if (!mounted) return;
      setState(() {
        _catalog = r[0];
        _selected
          ..clear()
          ..addAll(r[1].map((a) => a.id));
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadFailed = true);
        showErrorDialog(context, errorMessage(e), title: 'Không tải được danh sách dị ứng');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<ProfileRepository>().saveAllergies(_selected.toList());
      if (mounted) showSnack(context, 'Đã lưu danh sách dị ứng');
    } catch (e) {
      if (mounted) showErrorDialog(context, errorMessage(e), title: 'Không lưu được');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dị ứng thực phẩm')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
              ? RetryView(onRetry: _load)
              : Column(children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                            'Chọn những nguyên liệu bạn dị ứng. Thực đơn được tạo sẽ tránh các nguyên liệu này.',
                            style: TextStyle(color: context.textMuted)),
                        AllergenGroupedChips(
                          catalog: _catalog,
                          selected: _selected,
                          onChanged: (a, v) =>
                              setState(() => v ? _selected.add(a.id) : _selected.remove(a.id)),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text('Lưu (${_selected.length} mục đã chọn)'),
                        ),
                      ),
                    ),
                  ),
                ]),
    );
  }
}
