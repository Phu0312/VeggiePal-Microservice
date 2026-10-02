/// Công thức món chay (meal-service: Recipe).
class RecipeItem {
  final int id;
  final String name;
  final String mealType; // BREAKFAST | LUNCH | DINNER | ANY
  final String ingredients; // chuỗi, các nguyên liệu ngăn cách bằng dấu phẩy
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? instructions;
  final List<String> allergenCodes;

  const RecipeItem({
    required this.id,
    required this.name,
    required this.mealType,
    required this.ingredients,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.instructions,
    this.allergenCodes = const [],
  });

  factory RecipeItem.fromJson(Map<String, dynamic> j) => RecipeItem(
        id: (j['id'] as num).toInt(),
        name: '${j['name']}',
        mealType: '${j['mealType'] ?? 'ANY'}',
        ingredients: '${j['ingredients'] ?? ''}',
        calories: (j['calories'] as num?)?.toDouble() ?? 0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0,
        carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0,
        instructions: j['instructions'] as String?,
        allergenCodes: '${j['allergenCodes'] ?? ''}'
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      );

  List<String> get ingredientList => ingredients
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

/// Một nguyên liệu trong tủ của người dùng (meal-service: UserIngredient).
class PantryItem {
  final int id;
  final String name;
  final String? quantity;
  final String? unit;
  final DateTime? expiryDate;

  const PantryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.expiryDate,
  });

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        id: (j['id'] as num).toInt(),
        name: '${j['name']}',
        quantity: j['quantity'] as String?,
        unit: j['unit'] as String?,
        expiryDate: j['expiryDate'] == null ? null : DateTime.tryParse('${j['expiryDate']}'),
      );

  /// "500 g", "2", hoặc rỗng nếu chưa nhập.
  String get amountText => [
        if ((quantity ?? '').trim().isNotEmpty) quantity!.trim(),
        if ((unit ?? '').trim().isNotEmpty) unit!.trim(),
      ].join(' ');

  /// Số ngày còn lại tới hạn sử dụng (âm = đã hết hạn); null nếu không có hạn.
  int? get daysLeft {
    final e = expiryDate;
    if (e == null) return null;
    final today = DateTime.now();
    return DateTime(e.year, e.month, e.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }
}
