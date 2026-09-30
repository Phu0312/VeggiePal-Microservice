import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/mock_fallback.dart';
import '../../../core/widgets/common_widgets.dart' show mockImage;

class Place {
  final int id;
  final String name;
  final String address;
  final String? description;
  final String type;
  final List<String> dishes;
  final double distanceKm;
  final double rating; // backend chưa có -> sinh ổn định theo id để UI nhất quán
  final String imageUrl;

  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.dishes,
    required this.distanceKm,
    required this.rating,
    required this.imageUrl,
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
      rating: 4.0 + (id % 10) / 10,
      imageUrl: mockImage(id),
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
  Future<List<Place>> nearby({String? food}) => withFallback(() async {
        final r = await _api.get(Endpoints.restaurantsNearby, query: {
          'lat': defaultLat,
          'lng': defaultLng,
          'radiusKm': 20,
          if (food != null && food.isNotEmpty) 'food': food,
        });
        return asList(r)
            .map((e) => Place.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }, () {
        final list = food == null || food.isEmpty
            ? [..._mock]
            : [..._mock.where((p) => p.matches(food)), ..._mock.where((p) => !p.matches(food))];
        return list;
      });

  static final _mock = [
    Place(id: 1, name: 'Tịnh Tâm Chay', address: '12 Nguyễn Huệ, Q.1', type: 'Nhà hàng chay', dishes: ['Bún riêu chay', 'Cơm chiên nấm', 'Đậu hũ sốt'], distanceKm: 0.8, rating: 4.6, imageUrl: mockImage(0)),
    Place(id: 2, name: 'Green Leaf Vegan', address: '45 Lê Lợi, Q.1', type: 'Quán vegan', dishes: ['Salad quinoa', 'Burger nấm', 'Sinh tố xanh'], distanceKm: 1.4, rating: 4.8, imageUrl: mockImage(1)),
    Place(id: 3, name: 'An Lạc Quán', address: '88 Pasteur, Q.3', type: 'Quán cơm chay', dishes: ['Cơm tấm chay', 'Canh nấm', 'Chả giò chay'], distanceKm: 2.1, rating: 4.4, imageUrl: mockImage(2)),
    Place(id: 4, name: 'Cửa hàng Rau Củ Sạch Bến Thành', address: '3 Lê Thánh Tôn, Q.1', type: 'Cửa hàng thực phẩm', dishes: ['Rau hữu cơ', 'Đậu hạt', 'Nấm tươi'], distanceKm: 2.9, rating: 4.5, imageUrl: mockImage(3)),
    Place(id: 5, name: 'Hương Sen Chay', address: '210 Cách Mạng Tháng 8, Q.10', type: 'Nhà hàng chay', dishes: ['Lẩu nấm chay', 'Bún Huế chay', 'Chè sen'], distanceKm: 4.3, rating: 4.7, imageUrl: mockImage(4)),
  ];
}
