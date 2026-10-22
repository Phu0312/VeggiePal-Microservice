import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';

class Place {
  final int id;
  final String name;
  final String address;
  final String? description;
  final String type;
  final List<String> dishes;
  final double distanceKm;
  final String? imageUrl; // backend chưa có ảnh quán -> VegImage hiện placeholder

  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.dishes,
    required this.distanceKm,
    this.imageUrl,
    this.description,
  });

  /// Map từ RestaurantService.findNearby: supportedDishes là chuỗi ngăn cách bằng dấu phẩy.
  factory Place.fromJson(Map<String, dynamic> j) {
    final id = (j['id'] as num).toInt();
    final dishes = '${j['supportedDishes'] ?? ''}'
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return Place(
      id: id,
      name: '${j['name']}',
      address: '${j['address'] ?? ''}',
      description: j['description'] as String?,
      type: '${j['type'] ?? ''}',
      dishes: dishes,
      distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
      imageUrl: j['imageUrl'] as String?,
    );
  }

  bool matches(String kw) {
    final k = kw.toLowerCase();
    return name.toLowerCase().contains(k) ||
        dishes.any((d) => d.toLowerCase().contains(k));
  }
}

class PlacesRepository {
  final ApiClient _api;
  PlacesRepository(this._api);

  /// Vị trí mặc định (TP.HCM). Có thể thay bằng GPS (geolocator) sau này.
  static const defaultLat = 10.7769, defaultLng = 106.7009;

  // GET /restaurants/nearby?lat&lng&radiusKm&food= (công khai, backend đã sắp xếp món khớp lên đầu).
  Future<List<Place>> nearby({String? food}) async {
    final r = await _api.get(Endpoints.restaurantsNearby, query: {
      'lat': defaultLat,
      'lng': defaultLng,
      'radiusKm': 20,
      if (food != null && food.isNotEmpty) 'food': food,
    });
    return asList(r)
        .map((e) => Place.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
