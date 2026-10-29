// Model công thức của recipe-service (`/recipes`, `/ingredients`). BE không trả kcal của cả công thức,
// nhưng mỗi nguyên liệu trong công thức kèm dinh dưỡng trên 100g nên app tự cộng lại (xem Recipe.nutrition).

/// Trạng thái công thức (recipe-service: RecipeStatus).
const recipeStatusLabels = {
  'DRAFT': 'Bản nháp',
  'PUBLISHED': 'Đã đăng',
  'HIDDEN': 'Đang ẩn',
  'ARCHIVED': 'Đã xoá',
};

String recipeStatusLabel(String status) => recipeStatusLabels[status] ?? status;

/// Đơn vị nguyên liệu cho chọn khi tạo công thức. BE lưu IN HOA và chỉ nhận một số đơn vị nhất định.
const recipeUnitOptions = {
  'GRAM': 'gram',
  'KG': 'kg',
  'ML': 'ml',
  'TBSP': 'muỗng canh',
  'TSP': 'muỗng cà phê',
  'PIECE': 'quả / củ / miếng',
};

// Hệ số quy đổi ra gram. Chỉ đơn vị khối lượng quy đổi được; ml, muỗng, quả... cần khối lượng riêng
// của nguyên liệu nên app không tự suy ra.
const _gramsPerUnit = {
  'G': 1.0, 'GR': 1.0, 'GAM': 1.0, 'GRAM': 1.0, 'GRAMS': 1.0,
  'KG': 1000.0, 'KILO': 1000.0, 'KILOGRAM': 1000.0, 'KILOGRAMS': 1000.0,
  'MG': 0.001, 'MILLIGRAM': 0.001, 'MILLIGRAMS': 0.001,
};

double? _toGrams(double quantity, String unit) {
  final factor = _gramsPerUnit[unit.trim().toUpperCase()];
  return factor == null || quantity <= 0 ? null : quantity * factor;
}

/// "GRAM" -> "gram", "TBSP" -> "muỗng canh"; đơn vị lạ thì chữ thường.
String unitLabel(String unit) {
  final u = unit.trim().toUpperCase();
  for (final e in const {
    'G': 'gram', 'GR': 'gram', 'GAM': 'gram', 'GRAM': 'gram', 'GRAMS': 'gram',
    'TABLESPOON': 'muỗng canh', 'TBSP': 'muỗng canh',
    'TEASPOON': 'muỗng cà phê', 'TSP': 'muỗng cà phê',
    'PIECE': 'quả / củ / miếng', 'PIECES': 'quả / củ / miếng', 'PCS': 'quả / củ / miếng',
  }.entries) {
    if (e.key == u) return e.value;
  }
  return unit.trim().toLowerCase();
}

/// 200.0 -> "200", 1.5 -> "1.5", 0.25 -> "0.25" (tối đa 2 số lẻ).
String formatQuantity(double v) {
  final s = v.toStringAsFixed(2);
  return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
}

double? _dbl(Object? v) => v is num ? v.toDouble() : null;

/// Một nguyên liệu trong công thức (recipe-service: RecipeIngredientResponse).
class RecipeIngredient {
  final int ingredientId;
  final String name;
  final double quantity;
  final String unit;
  final String? note;
  final double? caloriesPer100g, proteinPer100g, carbsPer100g, fatPer100g;
  final bool? vegan;
  final bool allergen;

  const RecipeIngredient({
    required this.ingredientId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.note,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.vegan,
    this.allergen = false,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        ingredientId: (j['ingredientId'] as num).toInt(),
        name: '${j['ingredientName'] ?? ''}',
        quantity: _dbl(j['quantity']) ?? 0,
        unit: '${j['unit'] ?? ''}',
        note: j['note'] as String?,
        caloriesPer100g: _dbl(j['caloriesPer100g']),
        proteinPer100g: _dbl(j['proteinPer100g']),
        carbsPer100g: _dbl(j['carbsPer100g']),
        fatPer100g: _dbl(j['fatPer100g']),
        vegan: j['vegan'] as bool?,
        allergen: j['allergen'] == true,
      );

  /// "200 gram" (thiếu đơn vị thì chỉ có số lượng).
  String get amountText => [
        formatQuantity(quantity),
        if (unit.trim().isNotEmpty) unitLabel(unit),
      ].join(' ');

  bool get isNonVegan => vegan == false;

  bool get _hasNutrition => caloriesPer100g != null &&
      proteinPer100g != null &&
      carbsPer100g != null &&
      fatPer100g != null;
}

class RecipeStep {
  final int stepNumber;
  final String instruction;
  const RecipeStep(this.stepNumber, this.instruction);
}

/// Dinh dưỡng mỗi khẩu phần của công thức.
class RecipeNutrition {
  final int kcal;
  final double protein, carbs, fat;
  const RecipeNutrition(this.kcal, this.protein, this.carbs, this.fat);
}

/// Công thức (recipe-service: RecipeResponse).
class Recipe {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final int servings;
  final int? prepTime;
  final int? cookTime;
  final String status; // DRAFT | PUBLISHED | HIDDEN | ARCHIVED
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps; // đã sắp theo stepNumber
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    this.servings = 1,
    this.prepTime,
    this.cookTime,
    this.status = 'DRAFT',
    this.ingredients = const [],
    this.steps = const [],
    this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> j) {
    final steps = [
      for (final s in (j['steps'] as List? ?? const []))
        RecipeStep(((s as Map)['stepNumber'] as num?)?.toInt() ?? 0, '${s['instruction'] ?? ''}'),
    ]..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));
    return Recipe(
      id: (j['id'] as num).toInt(),
      userId: (j['userId'] as num?)?.toInt() ?? 0,
      title: '${j['title'] ?? ''}',
      description: j['description'] as String?,
      imageUrl: j['imageUrl'] as String?,
      servings: (j['servings'] as num?)?.toInt() ?? 1,
      prepTime: (j['prepTime'] as num?)?.toInt(),
      cookTime: (j['cookTime'] as num?)?.toInt(),
      status: '${j['status'] ?? 'DRAFT'}',
      ingredients: [
        for (final i in (j['ingredients'] as List? ?? const []))
          RecipeIngredient.fromJson(Map<String, dynamic>.from(i as Map)),
      ],
      steps: steps,
      createdAt: j['createdAt'] == null ? null : DateTime.tryParse('${j['createdAt']}'),
    );
  }

  /// Tổng thời gian chuẩn bị + nấu (phút); null nếu cả hai đều trống.
  int? get totalMinutes =>
      prepTime == null && cookTime == null ? null : (prepTime ?? 0) + (cookTime ?? 0);

  /// Dinh dưỡng mỗi khẩu phần. Null nếu có nguyên liệu chưa tính được (thiếu dữ liệu hoặc đơn vị
  /// không quy đổi được ra gram), vì cộng thiếu sẽ ra con số thấp hơn thực tế. Lý do xem [nutritionGapHint].
  RecipeNutrition? get nutrition {
    if (ingredients.isEmpty) return null;
    var kcal = 0.0, protein = 0.0, carbs = 0.0, fat = 0.0;
    for (final i in ingredients) {
      final grams = _toGrams(i.quantity, i.unit);
      if (grams == null || !i._hasNutrition) return null;
      final k = grams / 100;
      kcal += k * i.caloriesPer100g!;
      protein += k * i.proteinPer100g!;
      carbs += k * i.carbsPer100g!;
      fat += k * i.fatPer100g!;
    }
    final n = servings > 0 ? servings : 1;
    double one(double v) => (v / n * 10).round() / 10;
    return RecipeNutrition((kcal / n).round(), one(protein), one(carbs), one(fat));
  }

  /// Lý do chưa tính được dinh dưỡng vì đơn vị; null nếu mọi nguyên liệu đều quy đổi được.
  String? get nutritionGapHint {
    final units = <String>{};
    for (final i in ingredients) {
      if (_toGrams(i.quantity, i.unit) != null || i.quantity <= 0) continue;
      units.add(i.unit.trim().isEmpty ? 'đơn vị khác' : unitLabel(i.unit));
    }
    if (units.isEmpty) return null;
    return 'Chưa tính được dinh dưỡng vì có nguyên liệu tính bằng ${units.join(', ')} '
        '(hiện chỉ quy đổi được gram, kg, mg).';
  }

  List<String> get allergenNames => [for (final i in ingredients) if (i.allergen) i.name];
  List<String> get nonVeganNames => [for (final i in ingredients) if (i.isNonVegan) i.name];
}

/// Dữ liệu một nguyên liệu trong form (số lượng còn là chuỗi người dùng gõ).
class RecipeIngredientDraft {
  final int ingredientId;
  final String name;
  String quantity;
  String unit;
  String note;
  RecipeIngredientDraft({
    required this.ingredientId,
    required this.name,
    this.quantity = '',
    this.unit = 'GRAM',
    this.note = '',
  });
}

/// "0,5" hoặc "0.5" -> 0.5 (người dùng Việt hay gõ dấu phẩy); null nếu không phải số.
double? parseQuantity(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

/// Số lượng hợp lệ: tối thiểu 0,01 và tối đa 2 chữ số thập phân (cột decimal(10,2) và @DecimalMin của BE).
bool isValidQuantity(String text) {
  final t = text.trim();
  if (!RegExp(r'^\d{1,8}([.,]\d{1,2})?$').hasMatch(t)) return false;
  return (parseQuantity(t) ?? 0) >= 0.01;
}

/// Giới hạn độ dài khớp cột của recipe-service (BE không tự kiểm tra, vượt sẽ lỗi 500).
class RecipeLimits {
  RecipeLimits._();
  static const title = 200;
  static const description = 2000;
  static const imageUrl = 500;
  static const note = 300;
  static const instruction = 2000;
}
