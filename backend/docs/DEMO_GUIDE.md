# Hướng Dẫn Kịch Bản Demo Backend VeggiePal (Dành Cho Hội Đồng Đồ Án)

Tài liệu này cung cấp kịch bản trình diễn (Demo Script) từng bước đầy đủ, rõ ràng và mạch lạc nhất để sinh viên tự tin thuyết trình toàn bộ hệ thống Backend VeggiePal trước Giảng viên và Hội đồng chấm đồ án tốt nghiệp.

---

## 1. Chuẩn Bị & Khởi Động Hệ Thống

### 1.1. Cơ sở dữ liệu MySQL
Hệ thống sử dụng container MySQL 8.4 trên cổng `3307`:
```bash
docker start veggiepal-mysql
```
*(Cả 3 cơ sở dữ liệu `veggiepal_identity`, `veggiepal_nutrition`, `veggiepal_blog` đã được thiết lập sẵn sàng cùng dữ liệu mẫu chuẩn nghiệp vụ).*

### 1.2. Khởi chạy 4 dịch vụ Microservices (chạy trên 4 terminal riêng biệt):
```bash
# Terminal 1: Identity Service (Port 18081)
cd identity-service && mvn spring-boot:run

# Terminal 2: Nutrition Service (Port 18082)
cd nutrition-service && mvn spring-boot:run

# Terminal 3: Blog Service (Port 18083)
cd blog-service && mvn spring-boot:run

# Terminal 4: API Gateway (Port 18080)
cd api-gateway && mvn spring-boot:run
```

### 1.3. Cổng thông tin Swagger UI tập trung:
Mở trình duyệt truy cập:
👉 **`http://localhost:18080/swagger-ui.html`**
Tại thanh chọn Select a definition (góc trên bên phải), Giảng viên có thể xem trực quan tài liệu API của cả 3 dịch vụ:
- `Identity Service`
- `Nutrition Service`
- `Blog Service`

---

## 2. Kịch Bản Trình Diễn Chi Tiết (Full 10 Bước)

### TÀI KHOẢN MẪU ĐÃ CUNG CẤP SẴN:
- **Quản trị viên (ADMIN)**: `admin@veggiepal.com` / `Demo@123`
- **Người dùng mẫu (USER)**: `user@veggiepal.com` / `Demo@123`
- **Người dùng 2 (USER)**: `user2@veggiepal.com` / `Demo@123`

---

### BƯỚC 1: XÁC THỰC & ĐĂNG NHẬP (FR-01)
**Mục tiêu**: Chứng minh cơ chế bảo mật JWT, mã hóa BCrypt và phân quyền người dùng.

1. **Đăng nhập với tư cách Người dùng**:
```bash
curl -X POST http://localhost:18080/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"email":"user@veggiepal.com","password":"Demo@123"}'
```
*Kết quả*: Trả về `token` (JWT chứa claim `role: "USER"` và `userId: 2`).

2. **Đăng nhập với tư cách Quản trị viên**:
```bash
curl -X POST http://localhost:18080/api/auth/token \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@veggiepal.com","password":"Demo@123"}'
```
*Kết quả*: Trả về `token` (JWT chứa claim `role: "ADMIN"` và `userId: 1`).

---

### BƯỚC 2: KHÁCH VÃNG LAI DÙNG THỬ AI & HẠN NGẠCH 3 CÂU HỎI (FR-02 & FR-07)
**Mục tiêu**: Chứng minh quy tắc nghiệp vụ BR-03: Khách chưa đăng nhập được hỏi 3 câu dùng thử, câu thứ 4 bị chặn với mã HTTP 429.

1. **Câu hỏi 1 (Khách hỏi về B12)**:
```bash
curl -X POST http://localhost:18080/api/ai/chat/guest \
  -H "Content-Type: application/json" \
  -H "X-Guest-Id: demo-guest-device-999" \
  -d '{"message":"Người ăn thuần chay nên bổ sung vitamin B12 như thế nào?"}'
```
*Kết quả*: AI phản hồi chi tiết về nấm men dinh dưỡng, sữa hạt tăng cường vi chất và viên bổ sung B12. `questionsRemaining: 2`.

2. **Câu hỏi 2**:
```bash
curl -X POST http://localhost:18080/api/ai/chat/guest \
  -H "Content-Type: application/json" \
  -H "X-Guest-Id: demo-guest-device-999" \
  -d '{"message":"Gợi ý món ăn sáng thuần chay giàu protein"}'
```
*Kết quả*: AI phản hồi gợi ý sinh tố bơ chuối hạt sen, cháo yến mạch. `questionsRemaining: 1`.

3. **Câu hỏi 3**:
```bash
curl -X POST http://localhost:18080/api/ai/chat/guest \
  -H "Content-Type: application/json" \
  -H "X-Guest-Id: demo-guest-device-999" \
  -d '{"message":"Làm thế nào để ăn chay đủ chất đạm?"}'
```
*Kết quả*: AI phản hồi tư vấn các loại đậu và hạt. `questionsRemaining: 0`.

4. **Câu hỏi 4 (Vượt hạn ngạch - Bị từ chối)**:
```bash
curl -X POST http://localhost:18080/api/ai/chat/guest \
  -H "Content-Type: application/json" \
  -H "X-Guest-Id: demo-guest-device-999" \
  -d '{"message":"Cho tôi thêm thực đơn khác"}'
```
*Kết quả*: Trả về HTTP 429:
```json
{
  "code": 2030,
  "message": "You have used all 3 free trial questions. Please register or login to continue."
}
```

---

### BƯỚC 3: THÀNH VIÊN SỬ DỤNG AI CHATBOT KHÔNG GIỚI HẠN (FR-07)
**Mục tiêu**: Người dùng có tài khoản chat thoải mái, lưu trữ hội thoại theo phiên.

```bash
curl -X POST http://localhost:18080/api/ai/chat \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"message":"Chào trợ lý VeggiePal, tư vấn giúp tôi món chay thanh đạm giải nhiệt"}'
```
*Kết quả*: Tạo phiên hội thoại `conversationId`, trả về câu trả lời chuyên sâu và lưu vào lịch sử.

---

### BƯỚC 4: HỒ SƠ SỨC KHỎE, DỊ ỨNG & TỦ NGUYÊN LIỆU (FR-06)
**Mục tiêu**: Chuẩn bị dữ liệu cá nhân hóa cho thuật toán tạo thực đơn thông minh.

1. **Khai báo dị ứng (Người dùng dị ứng với Đậu phộng `PEANUT` và Mè `SESAME`)**:
```bash
curl -X PUT http://localhost:18080/api/nutrition/allergies \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"allergenIds":[4, 9]}'
```

2. **Thêm nguyên liệu có sẵn trong tủ lạnh**:
```bash
curl -X POST http://localhost:18080/api/nutrition/ingredients \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Đậu phụ non","quantity":"3 bìa","category":"Đậu","expiryDate":"2026-10-05"}'
```

---

### BƯỚC 5: TẠO THỰC ĐƠN THUẦN CHAY 7 NGÀY BẰNG AI (FR-06)
**Mục tiêu**: Thuật toán AI Rule-Based tự động sinh lịch ăn 7 ngày, đảm bảo:
- ❌ **Không bao giờ** chứa món có thành phần đậu phộng (`PEANUT`) hoặc vừng (`SESAME`) đã khai báo ở Bước 4.
- 🎯 **Ưu tiên** chọn món có "Đậu phụ non" trong tủ lạnh.
- ⚖️ **Cân đối** calo mỗi ngày phù hợp với mục tiêu giảm cân (`GIAM_CAN`).

1. **Sinh thực đơn**:
```bash
curl -X POST http://localhost:18080/api/nutrition/meal-plans/generate \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"goal":"GIAM_CAN","dailyCalorieTarget":1600}'
```
*Kết quả*: Trả về cấu trúc JSON 7 ngày (Day 1 - Day 7), mỗi ngày gồm Bữa sáng (Breakfast), Bữa trưa (Lunch), Bữa tối (Dinner), đi kèm lượng calo, protein, carbs, fat chi tiết.

2. **Thay thế một bữa ăn nếu không thích (`replace-meal`)**:
```bash
curl -X POST http://localhost:18080/api/nutrition/meal-plans/1/replace-meal \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"dayIndex":1,"mealType":"LUNCH"}'
```

---

### BƯỚC 6: TÌM NHÀ HÀNG CHAY GẦN ĐÂY BẰNG HAVERSINE (FR-09)
**Mục tiêu**: Tìm kiếm các quán chay quanh tọa độ GPS người dùng, tính khoảng cách chính xác theo km.

```bash
# Người dùng đang ở gần hồ Hoàn Kiếm, Hà Nội (21.0285, 105.8542), tìm trong bán kính 5km:
curl -X GET "http://localhost:18080/api/restaurants/nearby?latitude=21.0285&longitude=105.8542&radiusKm=5.0"
```
*Kết quả*: Danh sách các nhà hàng thuần chay như *Ưu Đàm Chay (0.61 km)*, *Sadhu (0.97 km)*, *Nàng Sen (4.45 km)* được sắp xếp từ gần đến xa kèm danh sách món đặc trưng.

---

### BƯỚC 7: ĐĂNG BÀI VIẾT & BỘ LỌC KIỂM DUYỆT TỰ ĐỘNG (FR-03 & FR-12)
**Mục tiêu**: Chứng minh quy tắc BR-02 & BR-06: Phát hiện từ khóa động vật và đưa vào hàng đợi kiểm duyệt.

1. **Người dùng đăng bài có chứa từ khóa vi phạm chuẩn thuần chay ("thịt bò", "hải sản")**:
```bash
curl -X POST http://localhost:18080/api/blogs \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "categoryId": 1,
    "title": "Chia sẻ kinh nghiệm làm món sốt ăn kèm",
    "content": "Tôi vừa thử nghiệm công thức nấu súp rau củ này và thấy rất hợp khi ăn kèm với thịt bò và hải sản tươi...",
    "publish": true
  }'
```
*Kết quả*: Bài viết KHÔNG được lên trang chủ ngay mà chuyển sang trạng thái:
`status: "PENDING"`, `moderationReason: "Phát hiện nguyên liệu không thuần chay (thịt bò, hải sản). Cần quản trị viên kiểm duyệt trước khi công khai."`
Đồng thời một bản ghi kiểm duyệt được tạo trong bảng `moderation_cases`.

---

### BƯỚC 8: QUẢN TRỊ VIÊN KIỂM DUYỆT NỘI DUNG (FR-10 & FR-12)
**Mục tiêu**: Quản trị viên xem hàng đợi kiểm duyệt và đưa ra quyết định phê duyệt hoặc từ chối.

1. **Admin xem hàng đợi các bài viết đang chờ duyệt**:
```bash
curl -X GET "http://localhost:18080/api/admin/moderation/queue?status=PENDING" \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

2. **Admin từ chối bài viết vi phạm**:
```bash
curl -X POST http://localhost:18080/api/admin/moderation/1/review \
  -H "Authorization: Bearer <ADMIN_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"decision":"REJECTED","reason":"Bài viết không tuân thủ tiêu chuẩn 100% thuần chay của VeggiePal."}'
```
*Kết quả*: Bài viết cập nhật sang `status: "REJECTED"`, ghi nhận `reviewedBy: 1` và thời gian đánh giá.

---

### BƯỚC 9: VIDEO NẤU ĂN THUẦN CHAY & TÓM TẮT TỰ ĐỘNG BẰNG AI (FR-08)
**Mục tiêu**: Người dùng chia sẻ video nấu ăn và AI trích xuất các bước cốt lõi.

1. **Đăng video hướng dẫn**:
```bash
curl -X POST http://localhost:18080/api/videos \
  -H "Authorization: Bearer <USER_TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "categoryId": 7,
    "title": "Hướng dẫn nấu Phở Chay ngọt nước dùng từ rau củ quả",
    "description": "Video chi tiết cách ninh nước dùng phở chay từ củ cải, mía lau kết hợp nấm hương xào thơm.",
    "videoUrl": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    "durationSeconds": 600,
    "publish": true
  }'
```
*Kết quả*: AI tự động sinh trường `summary`:
- **Chủ đề**: Hướng dẫn nấu Phở Chay ngọt nước dùng...
- **Nguyên liệu cốt lõi**: Nấm hương, củ quả tươi, hồi quế thảo quả.
- **Các bước chế biến**: 1. Sơ chế củ quả. 2. Ninh nước dùng trong 45 phút. 3. Trụng bánh phở và hoàn thiện.
- **Điểm sáng dinh dưỡng**: 100% Thuần chay, giàu vitamin và chất khoáng.

---

### BƯỚC 10: QUẢN TRỊ VIÊN GIÁM SÁT HOẠT ĐỘNG AI (FR-10)
**Mục tiêu**: Cung cấp khả năng quan sát (observability), theo dõi thời gian phản hồi và độ tin cậy của AI.

1. **Xem nhật ký các lượt gọi AI**:
```bash
curl -X GET "http://localhost:18080/api/admin/ai/logs?limit=10" \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```

2. **Xem thống kê hiệu suất tổng thể**:
```bash
curl -X GET http://localhost:18080/api/admin/ai/metrics \
  -H "Authorization: Bearer <ADMIN_TOKEN>"
```
*Kết quả*:
```json
{
  "code": 1000,
  "result": {
    "totalOperations": 15,
    "successfulOperations": 15,
    "failedOperations": 0,
    "successRate": "100.0%",
    "avgDurationMs": 28.5,
    "activeProvider": "DEMO_RULE_BASED_PROVIDER",
    "status": "HEALTHY"
  }
}
```

---

## 3. Tóm Tắt Điểm Sáng Đồ Án (Key Selling Points)
1. **Kiến Trúc Microservices Chuẩn Mực**: Các dịch vụ độc lập, giao tiếp qua API Gateway, cơ chế chịu lỗi và bảo mật token JWT thống nhất.
2. **Khả Năng Vận Hành Ngoại Tuyến (Zero-Failure Offline Demo)**: Tất cả thuật toán AI (Meal Plan, Chatbot, Video Summarizer, Keyword Moderation) đều có Provider Demo chất lượng cao, phản hồi tức thì và không lo phụ thuộc mạng internet phòng bảo vệ.
3. **Tuân Thủ Nghiệp Vụ Nghiêm Ngặt**: Kiểm soát 100% thuần chay (BR-06), hạn ngạch khách vãng lai (BR-03), kiểm duyệt nội dung tự động trước khi xuất bản (BR-02).
