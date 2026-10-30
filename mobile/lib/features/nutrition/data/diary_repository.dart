import '../../../core/constants/endpoints.dart';
import '../../../core/network/api_client.dart';
import 'diary_models.dart';

/// Mã lỗi của nutrition-service về nhật ký ăn uống, dịch riêng tại đây. Các mã 2012 (chưa tính được mục tiêu) và
/// 2013 (hồ sơ chưa đủ để tính mục tiêu) và 2014 (dưới 18 tuổi) có thông báo trong bảng toàn app; màn hình nhật ký
/// xử lý riêng hai mã 2013 và 2014.
const diaryErrorMessages = {
  2008: 'Vui lòng nhập tên món ăn.',
  2009: 'Giá trị dinh dưỡng phải từ 0 trở lên.',
  2010: 'Không tìm thấy món này trong nhật ký (có thể đã được xoá).',
  2011: 'Lượng nước mỗi lần thêm phải từ 1 đến 5000 ml.',
};

/// nutrition-service: nhật ký ăn uống, nước uống và vận động theo ngày. Cần JWT. Mọi lỗi được ném lại cho UI.
class DiaryRepository {
  final ApiClient _api;
  DiaryRepository(this._api);

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      final text = e.code == null ? null : diaryErrorMessages[e.code];
      if (text == null) rethrow;
      throw ApiException(text, code: e.code, statusCode: e.statusCode);
    }
  }

  // GET /nutrition/me/daily-summary?date=yyyy-MM-dd&goalType=LOSE|MAINTAIN|GAIN : nạp so với mục tiêu, nước, vận động
  // và các món trong ngày. Mục tiêu calo do BE hỏi ai-service theo hồ sơ + [goalType]; hồ sơ thiếu thì BE trả
  // 400 mã 2013, dưới 18 tuổi thì 400 mã 2014, ai-service lỗi thì 503 mã 2012.
  Future<DailySummary> summary(DateTime date, {String goalType = 'MAINTAIN'}) => _guard(() async {
        final r = await _api.get(Endpoints.dailySummary, query: {'date': isoDate(date), 'goalType': goalType});
        return DailySummary.fromJson(Map<String, dynamic>.from(r as Map));
      });

  // POST /nutrition/me/food-logs : ghi một món vào bữa [FoodDraft.meal] của ngày [date].
  Future<FoodEntry> addFood(DateTime date, FoodDraft draft) => _guard(() async {
        final r = await _api.post(Endpoints.foodLogs, body: draft.toJson(date));
        return FoodEntry.fromJson(Map<String, dynamic>.from(r as Map));
      });

  // DELETE /nutrition/me/food-logs/{id}
  Future<void> deleteFood(int id) => _guard(() async {
        await _api.delete(Endpoints.foodLog(id));
      });

  // POST /nutrition/me/water {date, amountMl} : cộng thêm [amountMl] (1-5000) vào lượng nước của ngày.
  Future<DailyActivity> addWater(DateTime date, int amountMl) => _guard(() async {
        final r = await _api.post(Endpoints.water, body: {'date': isoDate(date), 'amountMl': amountMl});
        return DailyActivity.fromJson(Map<String, dynamic>.from(r as Map));
      });

  // PUT /nutrition/me/daily-activity : chỉ các trường được truyền mới bị ghi đè, trường null giữ nguyên.
  Future<DailyActivity> saveActivity(
    DateTime date, {
    int? waterMl,
    int? waterTargetMl,
    int? exerciseMinutes,
    int? steps,
    int? caloriesBurned,
    String? note,
  }) =>
      _guard(() async {
        final r = await _api.put(Endpoints.dailyActivity, body: {
          'date': isoDate(date),
          'waterMl': ?waterMl,
          'waterTargetMl': ?waterTargetMl,
          'exerciseMinutes': ?exerciseMinutes,
          'steps': ?steps,
          'caloriesBurned': ?caloriesBurned,
          'activityNote': ?note,
        });
        return DailyActivity.fromJson(Map<String, dynamic>.from(r as Map));
      });
}
