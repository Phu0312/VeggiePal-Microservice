import 'package:flutter/foundation.dart';

/// Báo cho tab Thực đơn nạp lại chỉ số sức khỏe mới nhất khi nơi khác (Hồ sơ > Lịch sử sức khỏe)
/// vừa thêm/sửa bản ghi.
class HealthSync extends ChangeNotifier {
  int version = 0;

  void changed() {
    version++;
    notifyListeners();
  }
}
