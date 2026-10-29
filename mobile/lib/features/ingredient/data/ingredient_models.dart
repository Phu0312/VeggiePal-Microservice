// Nguyên liệu: danh mục chung của recipe-service (`/ingredients`) và "tủ nguyên liệu" của người dùng.
// Backend không có tủ nguyên liệu riêng cho người dùng, nên tủ được lưu trên máy (xem PantryController).

double? _dbl(Object? v) => v is num ? v.toDouble() : null;

/// Nguyên liệu trong danh mục chung (recipe-service: IngredientResponse). Dinh dưỡng tính trên 100g.
class Ingredient {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final double calories, protein, carbs, fat;
  final double? fiber;
  final bool vegan;
  final bool allergen;

  const Ingredient({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber,
    this.vegan = false,
    this.allergen = false,
  });

  factory Ingredient.fromJson(Map<String, dynamic> j) => Ingredient(
        id: (j['id'] as num).toInt(),
        name: '${j['name'] ?? ''}',
        description: j['description'] as String?,
        imageUrl: j['imageUrl'] as String?,
        calories: _dbl(j['caloriesPer100g']) ?? 0,
        protein: _dbl(j['proteinPer100g']) ?? 0,
        carbs: _dbl(j['carbsPer100g']) ?? 0,
        fat: _dbl(j['fatPer100g']) ?? 0,
        fiber: _dbl(j['fiberPer100g']),
        vegan: j['vegan'] == true,
        allergen: j['allergen'] == true,
      );

  bool get hasDescription => (description ?? '').trim().isNotEmpty;
}

/// Bộ lọc danh mục theo cờ `vegan` / `allergen` của backend.
enum IngredientFilter {
  all('Tất cả'),
  vegan('Thuần chay'),
  allergen('Dễ gây dị ứng');

  final String label;
  const IngredientFilter(this.label);
}

/// Một nguyên liệu trong tủ của người dùng (lưu trên máy). Tên nên lấy từ danh mục để AI khớp được với
/// nguyên liệu của công thức; số lượng và đơn vị chỉ để ghi nhớ.
class PantryItem {
  final String name;
  final String quantity;
  final String unit;
  final DateTime? expiryDate;

  const PantryItem({required this.name, this.quantity = '', this.unit = '', this.expiryDate});

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        name: '${j['name'] ?? ''}',
        quantity: '${j['quantity'] ?? ''}',
        unit: '${j['unit'] ?? ''}',
        expiryDate: j['expiryDate'] == null ? null : DateTime.tryParse('${j['expiryDate']}'),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'expiryDate': expiryDate == null ? null : _iso(expiryDate!),
      };

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Khoá so sánh trùng tên: không phân biệt hoa/thường và khoảng trắng thừa.
  String get key => normalizeName(name);

  static String normalizeName(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  /// "500 g", "2", hoặc rỗng nếu chưa nhập.
  String get amountText => [
        if (quantity.trim().isNotEmpty) quantity.trim(),
        if (unit.trim().isNotEmpty) unit.trim(),
      ].join(' ');

  /// Số ngày còn lại tới hạn sử dụng (âm = đã hết hạn); null nếu không có hạn.
  int? daysLeft([DateTime? now]) {
    final e = expiryDate;
    if (e == null) return null;
    final today = now ?? DateTime.now();
    return DateTime(e.year, e.month, e.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  bool isExpired([DateTime? now]) => (daysLeft(now) ?? 0) < 0;
}
