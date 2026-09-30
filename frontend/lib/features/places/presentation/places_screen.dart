import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/places_repository.dart';

/// TAB 2 - Địa điểm quán chay.
/// Widget tree: Column
///   ├─ VegSearchBar
///   ├─ Hang chip goi y tu khoa mon
///   ├─ (nếu đã tìm) banner goi y theo tu khoa
///   └─ Expanded ListView các thẻ quán (_PlaceCard)
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  static const _suggestions = ['Bún riêu', 'Cơm chay', 'Salad', 'Lẩu nấm', 'Sinh tố'];
  final _search = TextEditingController();
  List<Place> _places = [];
  String _keyword = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load([String? kw]) async {
    setState(() {
      _loading = true;
      _keyword = (kw ?? _search.text).trim();
    });
    try {
      final r = await context.read<PlacesRepository>().nearby(food: _keyword);
      if (mounted) setState(() => _places = r);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tách quán phù hợp từ khóa (gợi ý) khỏi các quán còn lại (gần bạn).
    final matched = _keyword.isEmpty ? <Place>[] : _places.where((p) => p.matches(_keyword)).toList();

    return Column(children: [
      VegSearchBar(
        controller: _search,
        hint: 'Tìm quán chay, món ăn, thực phẩm...',
        onSubmitted: _load,
      ),
      SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: _suggestions.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (_, i) => ActionChip(
            label: Text(_suggestions[i]),
            onPressed: () {
              _search.text = _suggestions[i];
              _load(_suggestions[i]);
            },
          ),
        ),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (matched.isNotEmpty) ...[
                      Text('Gợi ý quán chay cho "$_keyword"',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                    ] else if (_keyword.isNotEmpty)
                      const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('Chưa có quán khớp món này, xem các quán gần bạn:')),
                    if (_keyword.isEmpty)
                      Text('Quán chay gần bạn',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    for (final p in _places)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PlaceCard(p, highlight: matched.contains(p)),
                      ),
                  ],
                ),
              ),
      ),
    ]);
  }
}

class _PlaceCard extends StatelessWidget {
  final Place p;
  final bool highlight;
  const _PlaceCard(this.p, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: highlight
            ? const BorderSide(color: AppColors.accent, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          VegImage(p.imageUrl, width: 96, height: 96),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.star, size: 16, color: AppColors.star),
                Text(' ${p.rating.toStringAsFixed(1)}  •  '),
                const Icon(Icons.place_outlined, size: 16, color: AppColors.primary),
                Text(' ${p.distanceKm} km'),
              ]),
              const SizedBox(height: 4),
              Text(p.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final d in p.dishes.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(d, style: const TextStyle(fontSize: 12)),
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
