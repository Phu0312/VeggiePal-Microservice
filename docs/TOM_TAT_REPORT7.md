# Tóm tắt Report 7 – VeggiePal

> Bản tóm tắt tiếng Việt để đọc nhanh. Nguồn chuẩn và đầy đủ là [REPORT7_FINAL_PROJECT_REPORT.md](REPORT7_FINAL_PROJECT_REPORT.md). Nếu hai file khác nhau thì theo Report 7.

## 1. Hệ thống là gì

VeggiePal là nền tảng cho người ăn chay: theo dõi sức khỏe và dị ứng, lập thực đơn 7 ngày bằng AI, chat với trợ lý dinh dưỡng, cộng đồng blog/video, tìm quán chay gần bạn, mua gói thành viên qua PayOS.

- **Client:** web React và mobile Flutter. Cả hai chỉ gọi qua một cổng duy nhất (API Gateway).
- **Backend:** 8 module Maven độc lập: gateway (8080, host 9080) và 7 service: identity 8081, nutrition 8082, blog 8083, recipe 8084, location 8085, ai 8086, payment 8087.
- **Dữ liệu:** MySQL 8.4, mỗi service một schema riêng (7 schema, 36 bảng). Service khác chỉ tham chiếu nhau bằng ID.
- **AI:** chạy local bằng llama.cpp với mô hình Qwen2.5-1.5B. Không dùng AI đám mây. Không còn bóc tách công thức từ video.

## 2. Cách đọc các sơ đồ (32 hình)

| Hình | Nói gì | Đọc như thế nào |
|---|---|---|
| 1–2 | Quy trình Scrum và nhánh Git | Nhánh feature → merge vào `dev` sau khi review → merge `dev` vào `main` để phát hành và deploy |
| 3 | Sơ đồ ngữ cảnh | Hệ thống là một khối; xung quanh là khách, user, admin và 4 dịch vụ ngoài: PayOS, Cloudinary, Google, SMTP |
| 4 | Use case | Ai làm được gì (UC1–UC11, UC8 đã bỏ) |
| 5–7 | Luồng màn hình mobile user, mobile admin, web | Mỗi ô là một màn hình, mũi tên là điều hướng |
| 8 | ERD khái niệm | 15 thực thể chính và quan hệ giữa chúng |
| 9 | Trạng thái blog/video | DRAFT, PUBLISHED, PENDING, REJECTED, BANNED. Kiểm duyệt AI quyết định chuyển trạng thái nào |
| 10 | Trạng thái đơn thanh toán | PENDING → PAID (webhook hoặc PayOS báo đã trả) hoặc → CANCELLED |
| 11 | Kiến trúc tổng thể | Gateway chia luồng tới 7 service; mũi tên nét đứt là gọi REST giữa các service |
| 12 | Docker và mạng | Chỉ 3 cổng ra máy chủ (9080, 4307, 5041) và llama ở 8088; còn lại nằm trong mạng Docker. Ngrok đưa webhook PayOS vào gateway |
| 13–14 | Cấu trúc package backend, web, mobile | Controller → service → repository; ai-service chia package theo tính năng |
| 15 | Mỗi service một CSDL | Quan hệ giữa các schema chỉ là "tham chiếu logic" bằng ID |
| 16–20 | ERD vật lý các schema | Bảng, khóa, quan hệ của identity/nutrition, blog, recipe/location, ai, payment |
| 21–22 | Lớp và chuỗi đăng nhập | Kiểm tra mật khẩu và trạng thái ACTIVE → cấp JWT 30 phút (HS256) + refresh token xoay vòng, mọi service tự kiểm JWT bằng khóa chung |
| 23–24 | Lớp và chuỗi tạo thực đơn | Lấy công thức và dị ứng → trừ hạn mức → loại món chứa dị ứng → hỏi mô hình → kiểm tra lại bằng code Java → lưu. Nếu mô hình lỗi thì dùng bộ lập kế hoạch dự phòng |
| 25–26 | Lớp và chuỗi thanh toán | Tạo đơn + link PayOS → quét VietQR → PayOS gọi webhook có chữ ký → khóa dòng đơn → kiểm tra số tiền → kích hoạt gói đúng một lần |
| 27 | Chuỗi kiểm duyệt | Blog/video/comment được ai-service kiểm; duyệt, từ chối hoặc chờ; AI không dùng được thì giữ ở PENDING cho admin |
| 28 | CI/CD | Chỉ chạy khi đổi `backend/`: test và package song song 8 module → build image + kiểm tra Compose → deploy lên máy tự lưu trữ (push `dev` hoặc `main`) |
| 29–32 | Quy trình người dùng | Đăng ký + hồ sơ sức khỏe, thực đơn, tìm quán gần, mua gói PayOS |

## 3. Những điểm quan trọng cần nhớ

**Chức năng:** 12 yêu cầu còn hiệu lực (FR-01 đến FR-13, FR-08 đã bỏ). Gói FREE/PLUS 29.000/PRO 59.000 VND. Chat mỗi ngày 5/20/50, thực đơn mỗi tháng 2/8/20. Khách chat thử 3 lần/ngày theo IP.

**Quy tắc nghiệp vụ chính:**
- Thực đơn phải loại món chứa chất gây dị ứng, và code kiểm tra lại kết quả của mô hình (BR-02).
- Webhook thanh toán phải đúng chữ ký, đúng số tiền, và không xử lý hai lần (BR-05).
- Khi AI kiểm duyệt không dùng được, nội dung được giữ lại để admin duyệt tay (BR-10).
- Chỉ tính mục tiêu calo cho người từ 18 tuổi (BR-11).
- AI chỉ chạy local, không có cổng cloud (BR-12).

**Bảo mật:** BCrypt cost 10; JWT HS256 sống 30 phút; refresh token chỉ dùng một lần và lưu dạng băm; webhook PayOS công khai nhưng phải đúng chữ ký; CORS chỉ cấu hình ở gateway; bí mật nằm trong biến môi trường.

**AI local:** llama.cpp trả lời qua `/v1/chat/completions`; timeout 10 giây kết nối, 120 giây đọc. Mô hình nhỏ nên có thể trả lời sai hoặc lặp; hệ thống bù bằng kiểm tra bằng code, bộ lập kế hoạch dự phòng và chuyển sang duyệt tay. Bản GPU cần driver NVIDIA hỗ trợ CUDA 12.8; không có thì dùng bản CPU.

**Thanh toán:** link PayOS hết hạn sau 15 phút. Nếu webhook không về, backend tự hỏi PayOS trạng thái đơn khi tạo đơn mới hoặc khi client hỏi trạng thái (tối đa 5 giây một lần), và kích hoạt gói đúng một lần.

**Kiểm thử:** 715 test method trong 105 lớp (đếm theo annotation). Các module đã chạy và đạt ở phiên cuối: api-gateway 10, payment 31, ai 197, recipe 38; Flutter 297 đạt. Identity, nutrition, blog, location cần MySQL nên chưa chạy ở đây (CI chạy chúng với container MySQL).

**Hạn chế đã nêu trong báo cáo:** mô hình nhỏ (1,5 tỷ tham số, ngữ cảnh 2.048 token) nên chất lượng chưa cao; không có thông báo đẩy; CI chỉ phủ backend; web chưa có test tự động; triển khai chạy trên một máy Docker cục bộ qua Ngrok.
