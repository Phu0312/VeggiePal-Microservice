import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/places_models.dart';

/// Nhãn "4.7 ★ • 530 m" của một quán.
class RatingDistance extends StatelessWidget {
  final Place place;
  const RatingDistance(this.place, {super.key});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.star_rounded, size: 17, color: AppColors.star),
        const SizedBox(width: 2),
        Text(formatRating(place.rating), style: const TextStyle(fontWeight: FontWeight.w700)),
        Text('  •  ${formatDistance(place.distanceKm)}', style: TextStyle(color: context.textMuted)),
      ]);
}

/// Nhãn nhỏ "Thuần chay 100%" / "Quán chay".
class KindChip extends StatelessWidget {
  final Place place;
  const KindChip(this.place, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = place.veganOnly ? context.cs.primary : context.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.leaf, size: 12, color: color),
        const SizedBox(width: 4),
        Text(place.kindLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

/// Mở link ngoài app (Google Maps, trình quay số); báo bằng snack nếu máy không mở được.
Future<void> openExternal(BuildContext context, Uri uri, String failMessage) async {
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok && context.mounted) showSnack(context, failMessage);
}

/// Thẻ quán trong danh sách: ảnh, tên, loại, đánh giá + khoảng cách, địa chỉ.
class PlaceCard extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;
  const PlaceCard({super.key, required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            VegImage(place.imageUrl, width: 88, height: 88, radius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 4),
                KindChip(place),
                const SizedBox(height: 4),
                RatingDistance(place),
                const SizedBox(height: 4),
                Text(place.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.textMuted, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Chi tiết một quán: ảnh, loại, đánh giá, khoảng cách, địa chỉ, số điện thoại và các nút
/// Chỉ đường / Gọi / Sao chép địa chỉ / Xem trên bản đồ ([onShowOnMap] null thì ẩn nút này).
Future<void> showPlaceSheet(BuildContext context, Place p, {VoidCallback? onShowOnMap}) {
  final tel = telUri(p.phoneNumber);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          VegImage(p.imageUrl, width: double.infinity, height: 170, radius: BorderRadius.circular(16)),
          const SizedBox(height: 12),
          Text(p.name, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
            KindChip(p),
            RatingDistance(p),
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(LucideIcons.mapPin, size: 18, color: ctx.cs.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(p.address.isEmpty ? 'Chưa có địa chỉ' : p.address)),
          ]),
          if (tel != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(LucideIcons.phone, size: 18, color: ctx.cs.primary),
              const SizedBox(width: 8),
              Text(p.phoneNumber!),
            ]),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => openExternal(ctx, directionsUri(p), 'Không mở được bản đồ chỉ đường'),
                icon: const Icon(LucideIcons.navigation),
                label: const Text('Chỉ đường'),
              ),
            ),
            if (tel != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openExternal(ctx, tel, 'Không mở được trình quay số'),
                  icon: const Icon(LucideIcons.phone),
                  label: const Text('Gọi'),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Row(children: [
            if (onShowOnMap != null)
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  onShowOnMap();
                },
                icon: const Icon(LucideIcons.map, size: 18),
                label: const Text('Xem trên bản đồ'),
              ),
            if (p.address.isNotEmpty)
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: p.address));
                  if (ctx.mounted) showSnack(ctx, 'Đã sao chép địa chỉ');
                },
                icon: const Icon(LucideIcons.copy, size: 18),
                label: const Text('Sao chép địa chỉ'),
              ),
          ]),
        ]),
      ),
    ),
  );
}
