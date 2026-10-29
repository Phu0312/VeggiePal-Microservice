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
}
