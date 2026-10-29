import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'places_models.dart';

/// Kết quả một lần xin vị trí.
enum LocationStatus {
  idle, // chưa xin
  loading,
  granted, // có vị trí thật
  denied, // người dùng từ chối quyền (có thể xin lại)
  deniedForever, // từ chối vĩnh viễn: chỉ bật lại được trong Cài đặt
  serviceOff, // dịch vụ định vị (GPS) của máy đang tắt
  unavailable, // không lấy được vị trí (hết thời gian chờ, lỗi thiết bị)
}

typedef LatLngPair = ({double lat, double lng});

/// Nguồn vị trí của máy; tách ra để test không cần GPS thật.
abstract class LocationSource {
  /// Quyền hiện tại, không bật hộp thoại xin quyền.
  Future<LocationPermission> permission();

  /// Xin quyền (hiện hộp thoại hệ thống nếu cần).
  Future<LocationPermission> requestPermission();

  Future<bool> serviceEnabled();

  Future<LatLngPair> currentPosition();

  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
}

class GeolocatorSource implements LocationSource {
  const GeolocatorSource();

  @override
  Future<LocationPermission> permission() => Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() => Geolocator.requestPermission();

  @override
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LatLngPair> currentPosition() async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    ).timeout(const Duration(seconds: 15));
    return (lat: p.latitude, lng: p.longitude);
  }

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

/// Vị trí của người dùng cho tab Quán chay. Luôn có [lat]/[lng] để tìm quán: vị trí thật khi đã có,
/// ngược lại là tâm TP.HCM. Chỉ hiện hộp thoại xin quyền khi người dùng bấm "Vị trí của tôi" ([request]);
/// [restoreIfGranted] dùng lại vị trí mà không hỏi nếu quyền đã được cấp từ trước.
class UserLocation extends ChangeNotifier {
  UserLocation(this._source);

  final LocationSource _source;

  LocationStatus status = LocationStatus.idle;
  LatLngPair? _position;

  LatLngPair get location => _position ?? (lat: defaultLat, lng: defaultLng);
  bool get isDefault => _position == null;
  bool get hasRealPosition => _position != null;

  /// Quyền đã được cấp thì lấy vị trí luôn; chưa cấp thì không làm gì (không hiện hộp thoại).
  Future<void> restoreIfGranted() async {
    try {
      final p = await _source.permission();
      if (p == LocationPermission.always || p == LocationPermission.whileInUse) await request();
    } catch (_) {
      // Không kiểm tra được quyền: giữ tâm mặc định.
    }
  }

  /// Xin quyền (nếu cần) rồi lấy vị trí hiện tại. Lỗi giữ lại vị trí cũ để lần thử lại thất bại
  /// không đẩy người dùng về tâm mặc định.
  Future<void> request() async {
    status = LocationStatus.loading;
    notifyListeners();
    try {
      if (!await _source.serviceEnabled()) {
        status = LocationStatus.serviceOff;
        return;
      }
      var p = await _source.permission();
      if (p == LocationPermission.denied) p = await _source.requestPermission();
      if (p == LocationPermission.deniedForever) {
        status = LocationStatus.deniedForever;
        return;
      }
      if (p == LocationPermission.denied || p == LocationPermission.unableToDetermine) {
        status = LocationStatus.denied;
        return;
      }
      _position = await _source.currentPosition();
      status = LocationStatus.granted;
    } catch (_) {
      status = LocationStatus.unavailable;
    } finally {
      notifyListeners();
    }
  }

  /// Bỏ vị trí thật để xem quán quanh tâm mặc định (người dùng đang ở xa khu vực có quán).
  void useDefault() {
    _position = null;
    status = LocationStatus.idle;
    notifyListeners();
  }

  Future<void> openSettings() async {
    if (status == LocationStatus.serviceOff) {
      await _source.openLocationSettings();
    } else {
      await _source.openAppSettings();
    }
  }
}
