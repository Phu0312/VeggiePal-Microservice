import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/features/recipe/data/recipe_models.dart';
import 'package:VeggiePal/features/recipe/data/recipe_repository.dart';

// JSON mô phỏng RecipeResponse của recipe-service: số lượng là BigDecimal ("200.00"), đơn vị IN HOA,
// các bước có thể không đúng thứ tự.
Map<String, dynamic> _json({String unit = 'GRAM', int servings = 2}) => {
      'id': 5,
      'userId': 9,
      'title': 'Đậu hũ sốt cà',
      'description': 'Món chay đơn giản',
      'imageUrl': null,
      'servings': servings,
      'prepTime': 10,
      'cookTime': 20,
      'status': 'PUBLISHED',
      'createdAt': '2026-10-20T08:00:00',
      'ingredients': [
        {
          'ingredientId': 1,
          'ingredientName': 'Đậu hũ',
          'quantity': 200.0,
          'unit': unit,
          'note': null,
          'caloriesPer100g': 100,
          'proteinPer100g': 10,
          'carbsPer100g': 4,
          'fatPer100g': 5,
          'vegan': true,
          'allergen': true,
        },
        {
          'ingredientId': 2,
          'ingredientName': 'Cà chua',
          'quantity': 0.5,
          'unit': 'KG',
          'caloriesPer100g': 20,
          'proteinPer100g': 1,
          'carbsPer100g': 4,
          'fatPer100g': 0,
          'vegan': false,
          'allergen': false,
        },
      ],
      'steps': [
        {'stepNumber': 2, 'instruction': 'Sốt'},
        {'stepNumber': 1, 'instruction': 'Chiên'},
      ],
    };

void main() {
  group('Recipe.fromJson', () {
    final r = Recipe.fromJson(_json());

    test('đọc thông tin chung, sắp bước theo stepNumber', () {
      expect(r.title, 'Đậu hũ sốt cà');
      expect(r.totalMinutes, 30);
      expect(r.steps.map((s) => s.instruction), ['Chiên', 'Sốt']);
    });

    test('ghép số lượng và đơn vị dễ đọc', () {
      expect(r.ingredients[0].amountText, '200 gram');
      expect(r.ingredients[1].amountText, '0.5 kg');
    });

    test('cảnh báo nguyên liệu dễ dị ứng / không thuần chay', () {
      expect(r.allergenNames, ['Đậu hũ']);
      expect(r.nonVeganNames, ['Cà chua']);
    });

    test('cộng dinh dưỡng từ nguyên liệu rồi chia theo khẩu phần', () {
      // 200g đậu hũ: 200 kcal, 20g đạm, 8g tinh bột, 10g béo; 500g cà chua: 100 kcal, 5g đạm, 20g tinh bột, 0g béo.
      final n = r.nutrition!;
      expect(n.kcal, 150); // (200 + 100) / 2 khẩu phần
      expect(n.protein, 12.5);
      expect(n.carbs, 14);
      expect(n.fat, 5);
      expect(r.nutritionGapHint, isNull);
    });
  });

  test('không tính dinh dưỡng khi có đơn vị không quy đổi được ra gram', () {
    final r = Recipe.fromJson(_json(unit: 'TBSP'));
    expect(r.nutrition, isNull);
    expect(r.nutritionGapHint, contains('muỗng canh'));
  });

  test('thiếu dữ liệu dinh dưỡng của nguyên liệu thì không tính', () {
    final j = _json();
    (j['ingredients'] as List).first['caloriesPer100g'] = null;
    expect(Recipe.fromJson(j).nutrition, isNull);
  });

  test('isValidQuantity: tối thiểu 0,01 và tối đa 2 số thập phân, nhận cả dấu phẩy', () {
    expect(isValidQuantity('200'), isTrue);
    expect(isValidQuantity('0,5'), isTrue);
    expect(isValidQuantity('0.01'), isTrue);
    expect(isValidQuantity('0'), isFalse);
    expect(isValidQuantity('0.001'), isFalse);
    expect(isValidQuantity('1.234'), isFalse);
    expect(isValidQuantity('abc'), isFalse);
    expect(isValidQuantity(''), isFalse);
  });

  test('formatQuantity bỏ số 0 thừa', () {
    expect(formatQuantity(200), '200');
    expect(formatQuantity(1.5), '1.5');
    expect(formatQuantity(0.25), '0.25');
  });

  test('RecipePayload đánh số bước từ 1, đổi dấu phẩy và để trống ghi chú thành null', () {
    final body = RecipePayload(
      title: ' Canh chua ',
      description: '',
      imageUrl: '',
      servings: 3,
      prepTime: null,
      cookTime: 15,
      ingredients: [
        RecipeIngredientDraft(
            ingredientId: 7, name: 'Dứa', quantity: '0,5', unit: 'KG', note: '  '),
      ],
      steps: ['Rửa', 'Nấu'],
    ).toJson();

    expect(body['title'], 'Canh chua');
    expect(body['prepTime'], isNull);
    final ing = (body['ingredients'] as List).single as Map;
    expect(ing['quantity'], 0.5);
    expect(ing['note'], isNull);
    expect(body['steps'], [
      {'stepNumber': 1, 'instruction': 'Rửa'},
      {'stepNumber': 2, 'instruction': 'Nấu'},
    ]);
  });
}
