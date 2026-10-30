import 'dart:math' as math;

// Quán chay quanh một điểm (location-service: `GET /restaurants/nearby`).

/// Chợ Bến Thành, TP.HCM: tâm dùng khi chưa có vị trí thật (người dùng từ chối quyền hoặc tắt định vị).
const defaultLat = 10.7725, defaultLng = 106.698;

/// Backend giới hạn bán kính tối đa 10 km.
const radiusOptionsKm = [1, 3, 5, 10];
const defaultRadiusKm = 5;
const maxRadiusKm = 10;

/// Một quán chay (location-service: RestaurantResponse).
class Place {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final double? rating;
  final bool veganOnly; // true = thuần chay 100%
  final String? imageUrl; // có thể null hoặc là ảnh minh hoạ
  final double distanceKm; // từ điểm tìm kiếm, làm tròn 2 chữ số

  const Place({
    required this.id,
    required this.name,
    this.address = '',
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.rating,
    this.veganOnly = false,
    this.imageUrl,
    this.distanceKm = 0,
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
        id: (j['id'] as num).toInt(),
        name: '${j['name'] ?? ''}',
        address: '${j['address'] ?? ''}',
        latitude: (j['latitude'] as num).toDouble(),
        longitude: (j['longitude'] as num).toDouble(),
        phoneNumber: j['phoneNumber'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
        veganOnly: j['veganOnly'] == true,
        imageUrl: j['imageUrl'] as String?,
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
      );

  String get kindLabel => veganOnly ? 'Thuần chay 100%' : 'Quán chay';
}

/// 0.53 -> "530 m", 1.14 -> "1.1 km", 2 -> "2 km".
String formatDistance(double km) {
  if (!km.isFinite || km < 0) return '';
  final meters = (km * 1000).round();
  if (meters < 1000) return '$meters m';
  final one = km.toStringAsFixed(1);
  return '${one.endsWith('.0') ? one.substring(0, one.length - 2) : one} km';
}

/// 4.7 -> "4.7"; thiếu rating -> "-".
String formatRating(double? rating) => rating == null || !rating.isFinite ? '-' : rating.toStringAsFixed(1);

// Chữ cái có dấu -> chữ cái gốc, mỗi nhóm một chữ gốc để không phải đếm vị trí khớp nhau.
const _accentGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};
final _accentToBase = {
  for (final e in _accentGroups.entries)
    for (final r in e.value.runes) String.fromCharCode(r): e.key,
};

/// Chữ thường, bỏ dấu tiếng Việt ("Phở Chay" -> "pho chay") để tìm không phân biệt dấu.
String normalizeText(String text) {
  final b = StringBuffer();
  for (final r in text.trim().toLowerCase().runes) {
    final c = String.fromCharCode(r);
    b.write(_accentToBase[c] ?? c);
  }
  return b.toString();
}

/// Lọc quán theo từ khoá trong tên hoặc địa chỉ (không phân biệt dấu). Từ khoá rỗng thì giữ nguyên.
List<Place> filterPlaces(List<Place> places, String keyword) {
  final needle = normalizeText(keyword);
  if (needle.isEmpty) return places;
  return places.where((p) => normalizeText('${p.name} ${p.address}').contains(needle)).toList();
}

enum PlaceSort {
  nearest('Gần nhất'),
  rating('Đánh giá cao');

  final String label;
  const PlaceSort(this.label);
}

/// Sắp xếp bản sao của danh sách. Backend đã xếp theo khoảng cách nên "gần nhất" chỉ giữ thứ tự;
/// "đánh giá cao" xếp rating giảm dần (chưa có rating xuống cuối), bằng nhau thì gần hơn trước.
List<Place> sortPlaces(List<Place> places, PlaceSort sort) {
  final copy = [...places];
  if (sort != PlaceSort.rating) return copy;
  return copy..sort((a, b) {
    final ra = a.rating ?? double.negativeInfinity, rb = b.rating ?? double.negativeInfinity;
    if (rb != ra) return rb.compareTo(ra);
    return a.distanceKm.compareTo(b.distanceKm);
  });
}

/// Link chỉ đường của Google Maps tới quán (mở app Google Maps nếu có, không thì trình duyệt).
Uri directionsUri(Place p) => Uri.parse(
    'https://www.google.com/maps/dir/?api=1&destination=${p.latitude},${p.longitude}');

/// "028 7309 3899" -> tel:02873093899; không có số -> null.
Uri? telUri(String? phone) {
  final digits = (phone ?? '').replaceAll(RegExp(r'[^\d+]'), '');
  return digits.isEmpty ? null : Uri.parse('tel:$digits');
}

/// Mức zoom vừa khít vòng bán kính trong khung bản đồ cao khoảng 500px (1 km ~ 14.8, 5 km ~ 12.5, 10 km ~ 11.5).
double zoomForRadius(num radiusKm) {
  if (radiusKm <= 0) return 12;
  final zoom = 14.8 - math.log(radiusKm) / math.ln2;
  return (zoom.clamp(9, 15) * 10).round() / 10;
}
