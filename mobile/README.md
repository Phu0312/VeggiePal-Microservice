# VeggiePal Mobile

Ứng dụng Flutter của VeggiePal. App gọi toàn bộ backend qua một API Gateway duy nhất (xem `backend/` trong repo này).

## Yêu cầu

- Flutter SDK tương thích với Dart `^3.13.2` (khai báo trong `pubspec.yaml`).
- Backend đang chạy qua Docker Compose (xem `backend/docker-compose.yml`). Gateway lộ ra cổng host `9080`.

## Cấu hình

1. Tạo file `.env` từ mẫu:

   ```powershell
   Copy-Item .env.example .env
   ```

   `.env` đã được gitignore, không commit. File này được đóng gói vào app như một asset nên không để secret thật vào đó.

2. Các biến trong `.env`:

   | Biến | Ý nghĩa |
   |---|---|
   | `API_BASE_URL` | URL của gateway, kèm `/api`. Để trống thì app tự chọn theo nền tảng (bên dưới). |
   | `GOOGLE_CLIENT_ID` | OAuth Web client ID cho nút "Tiếp tục với Google". Phải trùng `GOOGLE_CLIENT_ID` của identity-service. Để trống thì nút Google báo chưa cấu hình. |
   | `GOOGLE_IOS_CLIENT_ID` | OAuth client ID loại iOS, chỉ cần khi build iOS. |

3. Thứ tự ưu tiên của `API_BASE_URL` (xem `lib/core/constants/endpoints.dart`):

   1. `--dart-define=API_BASE_URL=...`
   2. giá trị trong `.env`
   3. mặc định theo nền tảng:
      - Android emulator: `http://10.0.2.2:9080/api` (emulator không thấy `localhost` của máy host)
      - Web, Windows, iOS: `http://localhost:9080/api`

   Điện thoại thật: đặt `API_BASE_URL` thành IP LAN của máy chạy backend, ví dụ `http://192.168.1.10:9080/api`.

## Chạy

```powershell
flutter pub get
flutter run
```

Chạy với URL khác mà không sửa `.env`:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:9080/api
```

## Kiểm tra chất lượng

```powershell
flutter analyze
flutter test
```

Test nằm trong `test/` (model, repository, màn hình chính). Các test giả lập tầng mạng nên không cần backend đang chạy.

## Cấu trúc `lib/`

| Thư mục | Nội dung |
|---|---|
| `core/` | Hằng số và endpoint, client mạng, lưu trữ phiên đăng nhập, theme, tiện ích, widget dùng chung |
| `features/` | Từng nhóm chức năng: `auth`, `home`, `blog`, `community`, `recipe`, `menu_planner`, `ai_nutrition`, `nutrition`, `ingredient`, `video`, `places`, `payment`, `profile`, `notifications`, `admin` |
| `navigation/` | Thanh điều hướng dưới và màn hình chính |
| `main.dart` | Điểm vào, nạp `.env` và khởi tạo app |

Báo cáo của dự án (`docs/PRM_CAPSTONE.md`) mô tả chi tiết các chức năng của app mobile.
