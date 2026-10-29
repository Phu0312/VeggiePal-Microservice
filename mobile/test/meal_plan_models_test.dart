import 'package:flutter_test/flutter_test.dart';
import 'package:VeggiePal/features/menu_planner/data/meal_plan_models.dart';

// JSON mô phỏng phản hồi của ai-service (MealPlanResponse): `plan.days[].meals[]` chỉ có recipeId,
// ngày không theo thứ tự và `day` / `mealType` không đảm bảo hoa thường.
Map<String, dynamic> _planJson() => {
      'id': 7,
      'name': 'Thực đơn 12/10 - 18/10',
      'goal': 'Giảm cân: ăn thanh đạm',
      'goalType': 'LOSE',
      'version': 3,
      'isFavorite': true,
      'createdAt': '2026-10-12T08:30:00',
      'plan': {
        'days': [
          {
            'day': 'wednesday',
            'targetMet': false,
            'targetDeviations': {
              'calories': {'actual': 1200.5, 'min': 1500, 'max': 1800},
              'protein': {'actual': 40, 'min': 60},
            },
            'nutritionTotals': {'calories': 1200.5, 'protein': 40, 'carbohydrate': 180, 'fat': 30},
            'meals': [
              {'mealType': 'DINNER', 'recipeId': 3, 'note': 'Nhẹ bụng'},
              {
                'mealType': 'breakfast',
                'recipeId': 1,
                'note': 'Đủ chất',
                'servingMultiplier': 1.25,
                'nutrition': {'calories': 400, 'protein': 15, 'carbohydrate': 60, 'fat': 10},
              },
            ],
          },
          {
            'day': 'MONDAY',
            'targetMet': true,
            'targetDeviations': {
              'fat': {'actual': 70, 'max': 60},
            },
            'meals': <dynamic>[],
          },
        ],
        'constraints': {
          'dailyNutritionTarget': {'minCalories': 1500, 'maxCalories': 1800, 'minProtein': 60},
        },
      },
    };

void main() {
  group('MealPlan.fromJson', () {
    final plan = MealPlan.fromJson(_planJson());

    test('đọc thông tin chung và mục tiêu dinh dưỡng', () {
      expect(plan.id, 7);
      expect(plan.version, 3);
      expect(plan.isFavorite, isTrue);
      expect(plan.goalSummary, 'Giảm cân · ăn thanh đạm');
      expect(plan.target!.lines, [
        ('Năng lượng', '1500–1800 kcal'),
        ('Đạm', '≥ 60 g'),
      ]);
    });

    test('sắp ngày T2 -> CN và chuẩn hoá khoá thứ', () {
      expect(plan.days.map((d) => d.day), ['MONDAY', 'WEDNESDAY']);
      expect(plan.dayOf('WEDNESDAY'), isNotNull);
    });

    test('sắp bữa sáng -> trưa -> tối, đọc khẩu phần và dinh dưỡng', () {
      final wed = plan.dayOf('WEDNESDAY')!;
      expect(wed.meals.map((m) => m.mealType), ['BREAKFAST', 'DINNER']);
      expect(wed.meal('BREAKFAST')!.servingMultiplier, 1.25);
      expect(wed.meal('BREAKFAST')!.nutrition.calories, 400);
      expect(wed.meal('DINNER')!.servingMultiplier, 1); // không có trường = giữ nguyên khẩu phần
      expect(wed.totals.calories, 1200.5);
    });

    test('phân biệt ngày lỡ mục tiêu calo với lưu ý về đạm/tinh bột/béo', () {
      final wed = plan.dayOf('WEDNESDAY')!;
      expect(wed.missedTarget, isTrue);
      expect(wed.missedDeviations.map((d) => d.label), ['Năng lượng', 'Đạm']);
      expect(wed.macroNotes, isEmpty);

      final mon = plan.dayOf('MONDAY')!;
      expect(mon.missedTarget, isFalse);
      expect(mon.macroNotes.single.label, 'Chất béo');
      expect(mon.macroNotes.single.range, '≤ 60 g');

      expect(plan.missedDays, 1);
    });
  });

  test('thực đơn cũ chưa có goalType hiển thị nguyên mục tiêu', () {
    final json = _planJson()..['goalType'] = null;
    expect(MealPlan.fromJson(json).goalSummary, 'Giảm cân: ăn thanh đạm');
  });

  test('phiên bản cũ dựng thành thực đơn chỉ đọc', () {
    final current = MealPlan.fromJson(_planJson());
    final v = MealPlanVersion.fromJson({
      'version': 2,
      'name': 'Bản cũ',
      'goal': 'Giảm cân',
      'changeSummary': 'Đổi bữa tối',
      'createdAt': '2026-10-13T09:00:00',
      'plan': {'days': <dynamic>[]},
    });
    final old = v.asPlanOf(current);
    expect(old.viewingVersion, 2);
    expect(old.id, current.id);
    expect(old.isFavorite, current.isFavorite);
  });

  test('PlanRecipe sắp bước theo stepNumber và ghép số lượng + đơn vị', () {
    final r = PlanRecipe.fromJson({
      'id': 1,
      'title': 'Đậu hũ sốt cà',
      'prepTime': 10,
      'cookTime': 20,
      'ingredients': [
        {'ingredientName': 'Đậu hũ', 'quantity': 200, 'unit': 'g'},
        {'ingredientName': 'Muối', 'quantity': null, 'unit': null},
      ],
      'steps': [
        {'stepNumber': 2, 'instruction': 'Sốt'},
        {'stepNumber': 1, 'instruction': 'Chiên'},
      ],
    });
    expect(r.totalMinutes, 30);
    expect(r.ingredients.map((i) => i.amount), ['200 g', '']);
    expect(r.steps, ['Chiên', 'Sốt']);
  });

  test('todayDayKey đổi weekday của Dart sang khoá thứ', () {
    expect(todayDayKey(DateTime(2026, 10, 26)), 'MONDAY'); // 26/10/2026 là thứ Hai
    expect(todayDayKey(DateTime(2026, 11, 1)), 'SUNDAY');
  });
}
