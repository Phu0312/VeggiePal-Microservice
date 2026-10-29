import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../blog/data/blog_models.dart';
import '../../ingredient/data/ingredient_models.dart';
import 'admin_models.dart';

/// Nội dung gửi lên khi tạo / sửa nguyên liệu (recipe-service: IngredientRequest).
class IngredientPayload {
  final String name;
  final String description;
  final double calories, protein, carbs, fat;
  final double? fiber;
  final bool vegan;
  final bool allergen;
  final bool active;

  const IngredientPayload({
    required this.name,
    this.description = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.vegan = true,
    this.allergen = false,
    this.active = true,
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'description': description.trim(),
        'caloriesPer100g': calories,
        'proteinPer100g': protein,
        'carbsPer100g': carbs,
        'fatPer100g': fat,
        'fiberPer100g': fiber,
        'vegan': vegan,
        'allergen': allergen,
        'active': active,
      };
}

/// API dành cho ADMIN: kiểm duyệt nội dung, giám sát AI, thanh toán và quản lý nguyên liệu.
/// Danh mục do BlogRepository phụ trách. Mọi lỗi được ném lại cho UI hiển thị popup.
class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  PageData<T> _page<T>(dynamic r, int page, T Function(Map<String, dynamic>) map) {
    final m = r is Map ? r : const {};
    return PageData(
      asList(r).map((e) => map(Map<String, dynamic>.from(e as Map))).toList(),
      (m['page'] as num?)?.toInt() ?? page,
      (m['totalPages'] as num?)?.toInt() ?? 1,
      (m['totalElements'] as num?)?.toInt() ?? 0,
    );
  }

  // ---------------- kiểm duyệt nội dung (ai-service) ----------------

  // GET /ai/admin/moderation : các ca đang chờ (REVIEW_REQUIRED), cũ nhất trước.
  Future<List<ModerationCase>> pendingCases() async {
    final r = await _api.get(Endpoints.aiModeration);
    return asList(r).map((e) => ModerationCase.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  // PUT /ai/admin/moderation/{id} {decision: APPROVED|REJECTED, reason?}: backend áp quyết định lên nội dung gốc
  // (blog-service). Lỗi 6012 = nội dung gốc đã bị xoá, 6013 = ca đã được xử lý.
  Future<void> review(int caseId, {required bool approve, String? reason}) async {
    await _api.put(Endpoints.aiModerationCase(caseId), body: {
      'decision': approve ? 'APPROVED' : 'REJECTED',
      if ((reason ?? '').trim().isNotEmpty) 'reason': reason!.trim(),
    });
  }

  // DELETE /ai/admin/moderation/{id}?reason= : bỏ qua ca (DISMISSED), nội dung gốc KHÔNG đổi trạng thái.
  Future<void> dismiss(int caseId, {String? reason}) async {
    final q = (reason ?? '').trim();
    await _api.delete(
        q.isEmpty ? Endpoints.aiModerationCase(caseId) : '${Endpoints.aiModerationCase(caseId)}?reason=${Uri.encodeQueryComponent(q)}');
  }

  // ---------------- giám sát AI (ai-service) ----------------

  // GET /ai/admin/monitoring/summary?days= (backend giới hạn 1-90)
  Future<UsageSummary> usageSummary(int days) async {
    final r = await _api.get(Endpoints.aiUsageSummary, query: {'days': days});
    return UsageSummary.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /ai/admin/monitoring/logs/search?feature=&status=&page=&size=
  Future<PageData<UsageLog>> usageLogs({String? feature, String? status, int page = 0, int size = 20}) async {
    final r = await _api.get(Endpoints.aiUsageLogs, query: {
      if (feature != null) 'feature': feature,
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return _page(r, page, UsageLog.fromJson);
  }

  // GET /ai/admin/monitoring/models -> {chat, mealPlan, ...: tên model}
  Future<Map<String, String>> aiModels() async {
    final r = await _api.get(Endpoints.aiModels);
    return {for (final e in Map<String, dynamic>.from(r as Map).entries) e.key: '${e.value}'};
  }

  // GET /ai/admin/monitoring/limits
  Future<Map<String, num>> aiLimits() async {
    final r = await _api.get(Endpoints.aiLimits);
    return {
      for (final e in Map<String, dynamic>.from(r as Map).entries)
        if (e.value is num) e.key: e.value as num,
    };
  }

  // ---------------- thanh toán (payment-service) ----------------

  Map<String, dynamic> _range(DateTime? from, String? planCode) => {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (planCode != null) 'planCode': planCode,
      };

  // GET /admin/payments/summary?from=&planCode=
  Future<PaymentSummary> paymentSummary({DateTime? from, String? planCode}) async {
    final r = await _api.get(Endpoints.adminPaymentSummary, query: _range(from, planCode));
    return PaymentSummary.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /admin/payments/statistics?from=&planCode=
  Future<PaymentStatistics> paymentStatistics({DateTime? from, String? planCode}) async {
    final r = await _api.get(Endpoints.adminPaymentStatistics, query: _range(from, planCode));
    return PaymentStatistics.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /admin/payments/revenue?from=&planCode=&groupBy=DAY|MONTH : chỉ tính đơn đã thanh toán.
  Future<Revenue> paymentRevenue({DateTime? from, String? planCode, String groupBy = 'DAY'}) async {
    final r = await _api.get(Endpoints.adminPaymentRevenue, query: {..._range(from, planCode), 'groupBy': groupBy});
    return Revenue.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // GET /admin/payments/orders?status=&planCode=&from=&page=&size=
  Future<PageData<PaymentOrder>> paymentOrders(
      {String? status, DateTime? from, String? planCode, int page = 0, int size = 20}) async {
    final r = await _api.get(Endpoints.adminPaymentOrders, query: {
      ..._range(from, planCode),
      if (status != null) 'status': status,
      'page': page,
      'size': size,
    });
    return _page(r, page, PaymentOrder.fromJson);
  }

  // ---------------- nguyên liệu (recipe-service, chỉ ADMIN ghi) ----------------

  // POST /ingredients
  Future<Ingredient> createIngredient(IngredientPayload p) async {
    final r = await _api.post(Endpoints.ingredients, body: p.toJson());
    return Ingredient.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // PUT /ingredients/{id}
  Future<Ingredient> updateIngredient(int id, IngredientPayload p) async {
    final r = await _api.put(Endpoints.ingredientById(id), body: p.toJson());
    return Ingredient.fromJson(Map<String, dynamic>.from(r as Map));
  }

  // DELETE /ingredients/{id} : xoá hẳn (nguyên liệu đang có trong công thức có thể không xoá được).
  Future<void> deleteIngredient(int id) async {
    await _api.delete(Endpoints.ingredientById(id));
  }
}
