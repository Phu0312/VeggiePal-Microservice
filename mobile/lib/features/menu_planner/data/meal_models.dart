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
