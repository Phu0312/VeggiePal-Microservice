import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/places_models.dart';
import '../data/places_repository.dart';
import '../data/user_location.dart';
import 'place_widgets.dart';
import 'places_map.dart';

/// TAB 2 - Quán chay gần bạn.
/// Widget tree: Column
///   ├─ VegSearchBar            (lọc theo tên / địa chỉ ngay trên danh sách đã tải, không phân biệt dấu)
///   ├─ Hàng chip               (bán kính 1/3/5/10 km, chỉ quán thuần chay, sắp xếp)
///   ├─ _LocationBanner         (đang dùng vị trí thật hay tâm TP.HCM, xin quyền / mở Cài đặt)
///   ├─ Công tắc Danh sách | Bản đồ
///   └─ Expanded IndexedStack[ danh sách PlaceCard | PlacesMap ]
/// API: GET /restaurants/nearby?lat&lng&radiusKm&veganOnly (công khai, gần nhất trước, bán kính tối đa 10 km).
/// Gõ chữ thì lọc ngay trên danh sách đã tải; bấm Enter thì tìm trên toàn bộ quán bằng GET /restaurants/search
/// (không giới hạn bán kính, bán kính bị khoá cho tới khi xoá tìm kiếm).
/// Chỉ hỏi quyền vị trí khi người dùng bấm "Vị trí của tôi"; quyền đã được cấp từ trước thì dùng luôn.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final UserLocation _user;
  final _search = TextEditingController();
  final _map = MapController();

  int _radius = defaultRadiusKm;
  bool _veganOnly = false;
  PlaceSort _sort = PlaceSort.nearest;
  bool _showMap = false;
  String _keyword = '';
  String? _remoteKeyword; // khác null: đang xem kết quả tìm trên toàn bộ quán (GET /restaurants/search)

  List<Place> _places = [];
  bool _loading = true;
  bool _failed = false;
  int? _selectedId;
  int _generation = 0; // bỏ kết quả của lần tải cũ khi đã bắt đầu lần tải mới
  LatLngPair? _loadedFor;

  @override
  void initState() {
    super.initState();
    _user = UserLocation(context.read<LocationSource>())..addListener(_onLocationChanged);
    _search.addListener(() {
      if (_search.text != _keyword) setState(() => _keyword = _search.text);
      // Xoá hết chữ thì quay về danh sách quanh vị trí.
      if (_search.text.trim().isEmpty && _remoteKeyword != null) _clearRemoteSearch();
    });
    _load();
    _user.restoreIfGranted();
  }

  @override
  void dispose() {
    _user.dispose();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  void _onLocationChanged() {
    if (!mounted) return;
    setState(() {});
    if (_loadedFor != _user.location) {
      _load();
      _recenter();
    }
  }

  /// Đưa bản đồ về điểm tìm kiếm với mức zoom vừa khít vòng bán kính.
  void _recenter() {
    final c = _user.location;
    try {
      _map.move(LatLng(c.lat, c.lng), zoomForRadius(_radius));
    } catch (_) {
      // Bản đồ chưa dựng xong: lần dựng đầu đã dùng đúng tâm và zoom.
    }
  }

  Future<void> _load() async {
    final gen = ++_generation;
    final loc = _user.location;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repo = context.read<PlacesRepository>();
      final remote = _remoteKeyword;
      final r = remote == null
          ? await repo.nearby(lat: loc.lat, lng: loc.lng, radiusKm: _radius, veganOnly: _veganOnly)
          : await repo.search(keyword: remote, lat: loc.lat, lng: loc.lng, veganOnly: _veganOnly);
      if (!mounted || gen != _generation) return;
      setState(() {
        _places = r;
        _loadedFor = loc;
        if (!r.any((p) => p.id == _selectedId)) _selectedId = null;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() => _failed = true);
      showErrorDialog(context, errorMessage(e), title: 'Không tải được quán chay');
    } finally {
      if (mounted && gen == _generation) setState(() => _loading = false);
    }
  }

  /// Bấm Enter: tìm trên toàn bộ quán, không giới hạn bán kính. Để trống thì quay về danh sách quanh vị trí.
  void _submitSearch(String text) {
    FocusScope.of(context).unfocus();
    final k = text.trim();
    if (k.isEmpty) return _clearRemoteSearch();
    setState(() => _remoteKeyword = k);
    _load();
  }

  void _clearRemoteSearch() {
    if (_remoteKeyword == null) return;
    setState(() => _remoteKeyword = null);
    _load();
  }

  void _setRadius(int km) {
    if (km == _radius) return;
    setState(() => _radius = km);
    _load();
    _recenter();
  }

  void _showOnMap(Place p) {
    setState(() {
      _showMap = true;
      _selectedId = p.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _map.move(LatLng(p.latitude, p.longitude), 16);
      } catch (_) {}
    });
  }

  void _openDetail(Place p) => showPlaceSheet(context, p, onShowOnMap: () => _showOnMap(p));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Kết quả tìm trên toàn bộ quán đã khớp từ khoá ở server nên không lọc lại ở máy.
    final visible = sortPlaces(_remoteKeyword != null ? _places : filterPlaces(_places, _keyword), _sort);
    final loc = _user.location;

    return Column(children: [
      VegSearchBar(
        controller: _search,
        hint: 'Tìm theo tên quán hoặc địa chỉ...',
        onSubmitted: _submitSearch,
      ),
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          children: [
            for (final km in radiusOptionsKm) ...[
              ChoiceChip(
                  label: Text('$km km'),
                  selected: _radius == km,
                  onSelected: _remoteKeyword != null ? null : (_) => _setRadius(km)),
              const SizedBox(width: 8),
            ],
            FilterChip(
              avatar: const Icon(LucideIcons.leaf, size: 16),
              label: const Text('Chỉ thuần chay'),
              selected: _veganOnly,
              onSelected: (v) {
                setState(() => _veganOnly = v);
                _load();
              },
            ),
            const SizedBox(width: 8),
            for (final s in PlaceSort.values) ...[
              ChoiceChip(label: Text(s.label), selected: _sort == s, onSelected: (_) => setState(() => _sort = s)),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
      _LocationBanner(_user),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: FullWidthSegmented<bool>(
          options: [
            SegmentOption(false, 'Danh sách', icon: LucideIcons.list),
            SegmentOption(true, 'Bản đồ', icon: LucideIcons.map),
          ],
          selected: _showMap,
          onChanged: (v) => setState(() => _showMap = v),
        ),
      ),
      Expanded(
        child: _failed && _places.isEmpty
            ? RetryView(onRetry: _load)
            // IndexedStack giữ bản đồ (vị trí, mức zoom) khi chuyển qua lại với danh sách.
            : IndexedStack(index: _showMap ? 1 : 0, children: [
                _list(visible),
                Stack(children: [
                  PlacesMap(
                    controller: _map,
                    center: loc,
                    centerIsUser: _user.hasRealPosition,
                    radiusKm: _radius,
                    places: visible,
                    selectedId: _selectedId,
                    onSelect: (p) => setState(() => _selectedId = p?.id),
                    onOpenDetail: _openDetail,
                    onRecenter: _recenter,
                    tileProvider: context.read<MapTiles>().provider,
                  ),
                  if (_loading) const Positioned(top: 12, left: 12, child: _LoadingPill()),
                ]),
              ]),
      ),
    ]);
  }

  Widget _list(List<Place> visible) {
    if (_loading && _places.isEmpty) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: visible.isEmpty ? _empty() : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visible.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == 0) {
            if (_remoteKeyword != null) {
              return Row(children: [
                Expanded(
                  child: Text('${visible.length} quán khớp "$_remoteKeyword" trên toàn bộ quán (không giới hạn bán kính)',
                      style: TextStyle(fontSize: 12.5, color: context.textMuted)),
                ),
                TextButton(
                    onPressed: () {
                      _search.clear();
                      _clearRemoteSearch();
                    },
                    child: const Text('Xoá tìm kiếm')),
              ]);
            }
            return Text(
                _keyword.trim().isEmpty
                    ? '${visible.length} quán trong bán kính $_radius km'
                    : '${visible.length} quán khớp "${_keyword.trim()}"',
                style: TextStyle(fontSize: 12.5, color: context.textMuted));
          }
          final p = visible[i - 1];
          return PlaceCard(place: p, onTap: () => _openDetail(p));
        },
      ),
    );
  }

  Widget _empty() {
    final searching = _keyword.trim().isNotEmpty;
    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      Padding(
        padding: const EdgeInsets.all(40),
        child: Column(children: [
          Icon(LucideIcons.store, size: 56, color: context.textMuted),
          const SizedBox(height: 12),
          Text(
              searching
                  ? 'Không có quán nào khớp "${_keyword.trim()}".'
                  : 'Không có quán chay nào trong $_radius km quanh ${_user.hasRealPosition ? 'bạn' : 'trung tâm TP.HCM'}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted)),
          const SizedBox(height: 16),
          if (!searching && _radius < maxRadiusKm)
            OutlinedButton.icon(
              onPressed: () => _setRadius(radiusOptionsKm.firstWhere((k) => k > _radius, orElse: () => maxRadiusKm)),
              icon: const Icon(LucideIcons.maximize),
              label: const Text('Mở rộng bán kính'),
            ),
          if (!searching && _user.hasRealPosition)
            TextButton.icon(
              onPressed: _user.useDefault,
              icon: const Icon(LucideIcons.mapPin),
              label: const Text('Xem quanh trung tâm TP.HCM'),
            ),
        ]),
      ),
    ]);
  }
}

class _LoadingPill extends StatelessWidget {
  const _LoadingPill();

  @override
  Widget build(BuildContext context) => Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        color: context.cs.surface,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Đang tìm quán...', style: TextStyle(fontSize: 12.5)),
          ]),
        ),
      );
}

/// Cho biết đang tìm quanh vị trí thật hay tâm mặc định, và gợi ý bước tiếp theo khi chưa có vị trí.
class _LocationBanner extends StatelessWidget {
  final UserLocation user;
  const _LocationBanner(this.user);

  @override
  Widget build(BuildContext context) {
    final (message, action, onTap) = switch (user.status) {
      LocationStatus.loading => ('Đang xác định vị trí của bạn...', null, null),
      LocationStatus.granted when user.hasRealPosition => (
          'Đang tìm quanh vị trí của bạn.',
          'Về TP.HCM',
          user.useDefault
        ),
      LocationStatus.denied => (
          'Bạn chưa cho phép truy cập vị trí nên đang xem quanh trung tâm TP.HCM.',
          'Thử lại',
          user.request
        ),
      LocationStatus.deniedForever => (
          'Quyền vị trí đang bị tắt. Bật lại trong Cài đặt để tìm quán gần bạn.',
          'Mở Cài đặt',
          user.openSettings
        ),
      LocationStatus.serviceOff => (
          'Dịch vụ định vị của máy đang tắt nên đang xem quanh trung tâm TP.HCM.',
          'Bật định vị',
          user.openSettings
        ),
      LocationStatus.unavailable => (
          'Không lấy được vị trí của bạn lúc này, đang xem quanh trung tâm TP.HCM.',
          'Thử lại',
          user.request
        ),
      _ => ('Đang xem quanh trung tâm TP.HCM.', 'Vị trí của tôi', user.request),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(user.hasRealPosition ? LucideIcons.locateFixed : LucideIcons.mapPin, size: 18, color: context.cs.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          if (action != null) TextButton(onPressed: onTap, child: Text(action)),
        ]),
      ),
    );
  }
}
