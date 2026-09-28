# VeggiePal Backend - Architecture & Requirements Traceability Matrix (RTM)

## 1. Tổng Quan Kiến Trúc (Architecture Overview)

VeggiePal là hệ sinh thái nền tảng số hỗ trợ lối sống thuần chay (100% Vegan), được thiết kế theo kiến trúc **Microservices** hướng dịch vụ trên nền tảng Java 21, Spring Boot 4.1.1, MySQL 8.4, MinIO và Spring Cloud Gateway.

```mermaid
graph TD
    Client["Client (Flutter App / Web / Postman)"] --> Gateway["API Gateway (Port 18080)"]
    
    Gateway -->|"Route: /api/auth/**, /api/users/**, /api/admin/users/**"| Identity["Identity Service (Port 18081)"]
    Gateway -->|"Route: /api/nutrition/**, /api/ai/**, /api/restaurants/**, /api/admin/ai/**"| Nutrition["Nutrition Service (Port 18082)"]
    Gateway -->|"Route: /api/blogs/**, /api/categories/**, /api/comments/**, /api/videos/**, /api/admin/moderation/**"| Blog["Blog Service (Port 18083)"]
    
    Identity --> DB_Id[("MySQL: veggiepal_identity")]
    Nutrition --> DB_Nut[("MySQL: veggiepal_nutrition")]
    Blog --> DB_Blog[("MySQL: veggiepal_blog")]
    
    Identity -.-> S3["MinIO S3 (Port 19000): Avatars"]
    Blog -.-> S3_Blog["MinIO S3 (Port 19000): Thumbnails & Videos"]
```

### Danh Sách Cổng (Port Mapping)
- **API Gateway**: `18080` (Tích hợp Swagger UI tổng hợp tại `/swagger-ui.html`)
- **Identity Service**: `18081`
- **Nutrition Service**: `18082`
- **Blog Service**: `18083`
- **MySQL Database**: `3307` (Host port, kết nối tới container `veggiepal-mysql`)
- **MinIO Storage**: `19000` (API), `19001` (Web Console)

---

## 2. Bảng Truy Vết Yêu Cầu Chức Năng (Requirements Traceability Matrix - RTM)

| Mã Yêu Cầu | Tên Yêu Cầu Chức Năng | Microservice Đảm Nhiệm | API Endpoints | Entities & Tables Liên Quan | Quy Tắc Nghiệp Vụ (BR) & Ghi Chú |
|:---|:---|:---|:---|:---|:---|
| **FR-01** | Xác thực & Quản lý tài khoản người dùng | `identity-service` | `POST /auth/register`<br>`POST /auth/token`<br>`POST /auth/introspect`<br>`POST /auth/logout`<br>`GET /users/me`<br>`PUT /users/me` | `User`<br>(`users`) | Mã hóa mật khẩu BCrypt, JWT Bearer Token, kiểm tra tài khoản bị khóa (`BLOCKED`/`INACTIVE`). |
| **FR-02** | Khách vãng lai truy cập & Dùng thử AI Chatbot | `nutrition-service`<br>`blog-service` | `POST /ai/chat/guest`<br>`GET /blogs`<br>`GET /restaurants` | `GuestAiUsage`<br>(`guest_ai_usage`) | Header `X-Guest-Id`. Giới hạn dùng thử đúng **3 câu hỏi**. Câu thứ 4 trả về HTTP 429 (`GUEST_AI_QUOTA_EXCEEDED`). |
| **FR-03** | Quản lý bài viết cộng đồng thuần chay | `blog-service` | `POST /blogs`<br>`GET /blogs/me`<br>`GET /blogs`<br>`GET /blogs/{id}`<br>`PUT /blogs/{id}`<br>`DELETE /blogs/{id}` | `Blog`<br>(`blogs`) | Người dùng sở hữu nội dung; hỗ trợ upload ảnh bìa (MinIO S3); tìm kiếm theo từ khóa và phân loại danh mục. |
| **FR-04** | Tương tác bài viết: Bình luận & Bỏ phiếu (Vote) | `blog-service` | `POST /comments`<br>`GET /comments`<br>`POST /comments/{id}/replies`<br>`POST /blogs/{id}/vote`<br>`DELETE /blogs/{id}/vote` | `Comment`<br>(`comments`)<br>`ContentVote`<br>(`content_votes`) | Bình luận đa cấp (hỗ trợ phân trang và reply); Vote giá trị `1` (thích) hoặc `-1` (bỏ thích); bấm 2 lần tự động hủy vote. |
| **FR-05** | Tìm kiếm & Đề xuất nội dung liên quan | `blog-service`<br>`nutrition-service` | `GET /blogs?keyword=...`<br>`GET /blogs/{id}/related`<br>`GET /nutrition/recipes?keyword=...`<br>`GET /videos?keyword=...` | `Blog`, `Recipe`, `Video` | Tìm kiếm bài viết theo từ khóa tiêu đề/nội dung, đề xuất 5 bài cùng danh mục, tìm kiếm công thức thuần chay. |
| **FR-06** | Tạo thực đơn thuần chay 7 ngày bằng AI | `nutrition-service` | `POST /nutrition/meal-plans/generate`<br>`POST /nutrition/meal-plans`<br>`GET /nutrition/meal-plans`<br>`GET /nutrition/meal-plans/{id}`<br>`POST /nutrition/meal-plans/{id}/replace-meal` | `MealPlan`<br>(`meal_plans`)<br>`Recipe`<br>(`recipes`)<br>`UserIngredient`<br>(`user_ingredients`) | Thuật toán AI Rule-Based loại trừ nghiêm ngặt các chất dị ứng của người dùng (`UserAllergy`), ưu tiên nguyên liệu có sẵn trong tủ, tính calo theo mục tiêu sức khỏe (Giảm cân, Tăng cơ, Duy trì). |
| **FR-07** | Trợ lý ảo AI Chatbot tư vấn dinh dưỡng chay | `nutrition-service` | `POST /ai/chat`<br>`GET /ai/chat/conversations`<br>`GET /ai/chat/conversations/{id}` | `ChatConversation`<br>(`chat_conversations`)<br>`ChatMessage`<br>(`chat_messages`) | Mô hình Demo Provider cục bộ nhận diện thông minh các chủ đề: thiếu chất B12, công thức món ăn, calo thực vật, duy trì bối cảnh hội thoại. |
| **FR-08** | Video hướng dẫn nấu ăn & Tóm tắt bằng AI | `blog-service` | `POST /videos`<br>`GET /videos`<br>`GET /videos/{id}`<br>`GET /videos/me`<br>`POST /videos/{id}/summarize` | `Video`<br>(`videos`) | Hỗ trợ lưu trữ thông tin video nấu ăn; module AI trích xuất tự động: Tóm tắt món, Nguyên liệu cốt lõi, Các bước nấu ăn và Điểm sáng dinh dưỡng. |
| **FR-09** | Tìm kiếm nhà hàng chay gần đây (Haversine) | `nutrition-service` | `GET /restaurants/nearby`<br>`GET /restaurants/{id}` | `Restaurant`<br>(`restaurants`) | Tính khoảng cách thực tế giữa GPS người dùng và nhà hàng bằng công thức Haversine; lọc theo bán kính `radiusKm` và sắp xếp theo độ tương thích món ăn. |
| **FR-10** | Quản trị hệ thống & Giám sát vận hành AI | `identity-service`<br>`nutrition-service` | `GET /admin/users`<br>`PUT /admin/users/{id}/status`<br>`GET /admin/ai/logs`<br>`GET /admin/ai/metrics` | `AiOperationLog`<br>(`ai_operation_logs`)<br>`User` | Quyền `ADMIN` kiểm tra danh sách tài khoản, kích hoạt/khóa người dùng vi phạm; theo dõi nhật ký hoạt động AI, thời gian phản hồi trung bình (latency) và tỷ lệ thành công. |
| **FR-11** | Quản lý danh mục bài viết & món ăn | `blog-service` | `GET /categories`<br>`GET /categories/{id}`<br>`POST /categories`<br>`PUT /categories/{id}`<br>`DELETE /categories/{id}` | `Category`<br>(`categories`) | Cây danh mục 2 cấp (`FOOD_TYPE`, `RECIPE_TYPE`). Cho phép Admin thêm/sửa/ẩn danh mục; bảo đảm tính toàn vẹn khi có bài viết đang sử dụng. |
| **FR-12** | Kiểm duyệt nội dung tự động & Hàng đợi Admin | `blog-service` | `GET /admin/moderation/queue`<br>`GET /admin/moderation/{id}`<br>`POST /admin/moderation/{id}/review` | `ModerationCase`<br>(`moderation_cases`) | Kiểm duyệt từ khóa tự động: từ ngữ thô tục/xúc phạm -> `REJECTED`; từ khóa chứa thịt/hải sản không thuần chay -> chuyển `PENDING` vào hàng đợi Admin để duyệt thủ công. |

---

## 3. Các Quy Tắc Nghiệp Vụ Cốt Lõi (Business Rules - BR)

1. **BR-01 (Bảo mật & Phân quyền)**:
   - Các API quản trị (`/admin/**`) yêu cầu token có claim `role: "ADMIN"`.
   - Mật khẩu người dùng được băm an toàn bằng thuật toán BCrypt.
2. **BR-02 (Kiểm duyệt nội dung trước khi công khai)**:
   - Mọi bài viết cộng đồng và video khi xuất bản đều phải đi qua bộ lọc kiểm duyệt.
   - Nội dung vi phạm tiêu chuẩn cộng đồng bị từ chối hoặc chuyển vào hàng đợi kiểm duyệt để quản trị viên đánh giá.
3. **BR-03 (Hạn ngạch dùng thử cho khách vãng lai)**:
   - Khách vãng lai (`Guest`) được dùng thử miễn phí 3 lượt chat AI với định danh `X-Guest-Id`. Sau 3 lượt, hệ thống từ chối và hướng dẫn đăng ký tài khoản.
4. **BR-04 (Cấu trúc phân cấp danh mục)**:
   - Cây danh mục giới hạn tối đa 2 cấp độ nhằm đảm bảo trải nghiệm người dùng tinh gọn, không phân nhánh quá sâu.
5. **BR-05 (An toàn dữ liệu - Không xóa cứng tài nguyên quan trọng)**:
   - Khi Admin gỡ bài viết vi phạm của người dùng, trạng thái được chuyển sang `BANNED` (ẩn khỏi cộng đồng nhưng giữ nguyên dữ liệu kiểm toán).
6. **BR-06 (Chuẩn mực 100% Thuần Chay - Vegan Integrity)**:
   - Danh mục dị ứng không bao gồm các nhóm có nguồn gốc động vật (thịt, cá, sữa bò, trứng) vì toàn bộ nền tảng mặc định 100% thuần chay.
   - Bộ lọc kiểm duyệt tự động phát hiện và cảnh báo các từ khóa chứa thành phần động vật.
7. **BR-07 (Quyền sở hữu tài nguyên)**:
   - Người dùng chỉ có quyền chỉnh sửa hoặc xóa bài viết, bình luận, video, tủ nguyên liệu do chính mình tạo ra.
