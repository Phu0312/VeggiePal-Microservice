import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'places_models.dart';

/// location-service: quán chay quanh một điểm (công khai, không cần đăng nhập).
/// Mọi lỗi được ném lại cho UI hiển thị popup.
class PlacesRepository {
  final ApiClient _api;
  PlacesRepository(this._api);

  // GET /restaurants/nearby?lat=&lng=&radiusKm=&veganOnly= : gần nhất trước, không phân trang.
  // radiusKm phải trong (0, 10] (lỗi 5002), toạ độ phải hợp lệ (lỗi 5001).
  Future<List<Place>> nearby({
    required double lat,
    required double lng,
    int radiusKm = defaultRadiusKm,
    bool veganOnly = false,
  }) async {
    final r = await _api.get(Endpoints.restaurantsNearby, query: {
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'veganOnly': veganOnly,
    });
    return asList(r).map((e) => Place.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // GET /restaurants/search?keyword=&veganOnly=&lat=&lng= : tìm theo tên hoặc địa chỉ trên TOÀN BỘ quán (không giới hạn
  // bán kính). Có lat/lng thì BE tính `distanceKm`; kết quả được xếp gần nhất trước ở đây vì BE không đảm bảo thứ tự.
  Future<List<Place>> search({
    required String keyword,
    required double lat,
    required double lng,
    bool veganOnly = false,
  }) async {
    final r = await _api.get(Endpoints.restaurantsSearch, query: {
      'keyword': keyword.trim(),
      'veganOnly': veganOnly,
      'lat': lat,
      'lng': lng,
    });
    final places = asList(r).map((e) => Place.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    places.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return places;
  }
}
