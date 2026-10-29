import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:VeggiePal/features/ingredient/data/ingredient_models.dart';
import 'package:VeggiePal/features/ingredient/data/pantry_controller.dart';

PantryItem _item(String name, {DateTime? expiry, String qty = '', String unit = ''}) =>
    PantryItem(name: name, quantity: qty, unit: unit, expiryDate: expiry);

void main() {
  final now = DateTime(2026, 10, 29, 15, 30); // giờ trong ngày không được ảnh hưởng số ngày còn lại

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Ingredient.fromJson đọc dinh dưỡng trên 100g và các cờ', () {
    final g = Ingredient.fromJson({
      'id': 3,
      'name': 'Đậu hũ',
      'description': 'Đậu hũ trắng',
      'imageUrl': null,
      'caloriesPer100g': 76,
      'proteinPer100g': 8.1,
      'carbsPer100g': 1.9,
      'fatPer100g': 4.8,
      'fiberPer100g': null,
      'vegan': true,
      'allergen': true,
    });
    expect(g.calories, 76);
    expect(g.protein, 8.1);
    expect(g.fiber, isNull);
    expect(g.vegan, isTrue);
    expect(g.allergen, isTrue);
    expect(g.hasDescription, isTrue);
  });

  group('PantryItem', () {
    test('lưu và đọc lại qua JSON, hạn dùng theo yyyy-MM-dd', () {
      final json = _item('Nấm hương', qty: '200', unit: 'g', expiry: DateTime(2026, 11, 2)).toJson();
      expect(json['expiryDate'], '2026-11-02');
      final back = PantryItem.fromJson(json);
      expect(back.name, 'Nấm hương');
      expect(back.amountText, '200 g');
      expect(back.expiryDate, DateTime(2026, 11, 2));
    });

    test('daysLeft tính theo ngày, không theo giờ', () {
      expect(_item('a', expiry: DateTime(2026, 10, 29)).daysLeft(now), 0);
      expect(_item('a', expiry: DateTime(2026, 10, 31)).daysLeft(now), 2);
      expect(_item('a', expiry: DateTime(2026, 10, 28)).daysLeft(now), -1);
      expect(_item('a').daysLeft(now), isNull);
      expect(_item('a', expiry: DateTime(2026, 10, 28)).isExpired(now), isTrue);
      expect(_item('a', expiry: DateTime(2026, 10, 29)).isExpired(now), isFalse);
    });

    test('so trùng tên không phân biệt hoa thường và khoảng trắng thừa', () {
      expect(_item('  Nấm   Hương ').key, _item('nấm hương').key);
    });
  });

  group('PantryController', () {
    test('chưa đăng nhập thì không thêm được', () {
      expect(PantryController().add(_item('Nấm')), isFalse);
    });

    test('không thêm trùng tên, không đổi tên thành tên đã có', () async {
      final c = PantryController()..bindUser(1);
      expect(c.add(_item('Nấm hương')), isTrue);
      expect(c.add(_item('nấm  HƯƠNG')), isFalse);
      expect(c.add(_item('Đậu hũ')), isTrue);

      final tofu = c.items.last;
      expect(c.update(tofu, _item('Nấm hương')), isFalse); // trùng nguyên liệu khác
      expect(c.update(tofu, _item('Đậu hũ', qty: '2', unit: 'bìa')), isTrue); // giữ tên, đổi số lượng
      expect(c.items.last.amountText, '2 bìa');

      c.remove(c.items.first);
      expect(c.items.map((e) => e.name), ['Đậu hũ']);
    });

    test('lưu theo tài khoản và nạp lại khi đăng nhập', () async {
      final a = PantryController()..bindUser(1);
      a.add(_item('Nấm hương'));
      await pumpEventQueue();

      final again = PantryController()..bindUser(1);
      await pumpEventQueue();
      expect(again.items.map((e) => e.name), ['Nấm hương']);

      final other = PantryController()..bindUser(2);
      await pumpEventQueue();
      expect(other.items, isEmpty); // tài khoản khác không thấy tủ của người trước

      again.bindUser(null); // đăng xuất xoá tủ khỏi bộ nhớ đang chạy
      expect(again.items, isEmpty);
    });

    test('namesForPlan bỏ đồ hết hạn, đồ sắp hết hạn trước, đồ không hạn sau cùng, giới hạn số lượng', () {
      final c = PantryController()..bindUser(1);
      c.add(_item('Không hạn'));
      c.add(_item('Hạn xa', expiry: DateTime(2026, 12, 1)));
      c.add(_item('Hết hạn', expiry: DateTime(2026, 10, 1)));
      c.add(_item('Sắp hết', expiry: DateTime(2026, 10, 30)));

      expect(c.namesForPlan(now: now), ['Sắp hết', 'Hạn xa', 'Không hạn']);
      expect(c.namesForPlan(max: 2, now: now), ['Sắp hết', 'Hạn xa']);
    });
  });
}
