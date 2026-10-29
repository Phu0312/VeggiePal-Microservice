import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../data/places_models.dart';
import 'place_widgets.dart';

/// Nguồn ô bản đồ. Mặc định dùng bộ tải của flutter_map (có lưu đệm trên máy); test thay bằng bộ tải không đụng
/// tới hệ thống tệp / mạng.
class MapTiles {
  final TileProvider? provider;
  const MapTiles([this.provider]);
}

/// Bản đồ quán chay (OpenStreetMap): vòng bán kính tìm kiếm, vị trí của bạn (chấm xanh dương) và ghim từng quán.
/// Bấm một ghim thì chọn quán đó và hiện thẻ tóm tắt ở dưới; bấm vào chỗ trống để bỏ chọn.
/// Cha điều khiển bản đồ qua [controller] (di chuyển tới một quán, về lại vị trí tìm kiếm).
class PlacesMap extends StatelessWidget {
  final MapController controller;
  final ({double lat, double lng}) center;
  final bool centerIsUser; // true = tâm là vị trí thật của người dùng
  final int radiusKm;
  final List<Place> places;
  final int? selectedId;
  final ValueChanged<Place?> onSelect;
  final ValueChanged<Place> onOpenDetail;
  final VoidCallback onRecenter;
  final TileProvider? tileProvider;

  const PlacesMap({
    super.key,
    required this.controller,
    required this.center,
    required this.centerIsUser,
    required this.radiusKm,
    required this.places,
    required this.selectedId,
    required this.onSelect,
    required this.onOpenDetail,
    required this.onRecenter,
    this.tileProvider,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(center.lat, center.lng);
    Place? selected;
    for (final p in places) {
      if (p.id == selectedId) selected = p;
    }
    final primary = context.cs.primary;

    return Stack(children: [
      FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: point,
          initialZoom: zoomForRadius(radiusKm),
          minZoom: 4,
          maxZoom: 18,
          onTap: (_, _) => onSelect(null),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            // OpenStreetMap yêu cầu ứng dụng khai báo định danh khi tải ô bản đồ.
            userAgentPackageName: 'com.veggiepal.mobile',
            tileProvider: tileProvider,
          ),
          CircleLayer(circles: [
            CircleMarker(
              point: point,
              radius: radiusKm * 1000.0,
              useRadiusInMeter: true,
              color: primary.withValues(alpha: 0.08),
              borderColor: primary.withValues(alpha: 0.5),
              borderStrokeWidth: 1.5,
            ),
          ]),
          MarkerLayer(markers: [
            // Điểm tìm kiếm: chấm xanh dương nếu là vị trí thật, ghim nhỏ nếu là tâm mặc định.
            Marker(
              point: point,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: centerIsUser ? Colors.blue : Colors.grey.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                ),
              ),
            ),
            for (final p in places)
              Marker(
                point: LatLng(p.latitude, p.longitude),
                width: p.id == selectedId ? 50 : 40,
                height: p.id == selectedId ? 50 : 40,
                child: GestureDetector(
                  onTap: () => onSelect(p),
                  child: _Pin(p, selected: p.id == selectedId),
                ),
              ),
          ]),
          const SimpleAttributionWidget(source: Text('© OpenStreetMap')),
        ],
      ),
      Positioned(
        right: 12,
        top: 12,
        child: FloatingActionButton.small(
          heroTag: 'places-recenter',
          tooltip: 'Về vị trí tìm kiếm',
          onPressed: onRecenter,
          child: const Icon(LucideIcons.locateFixed),
        ),
      ),
      if (selected != null)
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _SelectedCard(selected, onOpenDetail: () => onOpenDetail(selected!)),
        ),
    ]);
  }
}

class _Pin extends StatelessWidget {
  final Place place;
  final bool selected;
  const _Pin(this.place, {required this.selected});

  @override
  Widget build(BuildContext context) {
    final base = place.veganOnly ? AppColors.primary : AppColors.accent;
    final color = selected ? Colors.deepOrange : base;
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: Icon(LucideIcons.leaf, color: place.veganOnly || selected ? Colors.white : Colors.black87, size: selected ? 24 : 19),
    );
  }
}

class _SelectedCard extends StatelessWidget {
  final Place place;
  final VoidCallback onOpenDetail;
  const _SelectedCard(this.place, {required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpenDetail,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(place.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                RatingDistance(place),
                Text(place.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: context.textMuted)),
              ]),
            ),
            IconButton.filled(
              tooltip: 'Chỉ đường',
              onPressed: () => openExternal(context, directionsUri(place), 'Không mở được bản đồ chỉ đường'),
              icon: const Icon(LucideIcons.navigation, size: 20),
            ),
          ]),
        ),
      ),
    );
  }
}
