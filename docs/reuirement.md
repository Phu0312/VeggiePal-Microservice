Nhóm các bạn phát triển một ứng dụng hoàn chỉnh bao gồm:
•	Backend (tuỳ chọn): viết bằng .NET 6/7/8 (Web API)
•	Frontend (tuỳ chọn):
o	Web app: Tùy chọn (HTML/CSS/JS hoặc framework như React/Vue/Angular…)
o	Mobile app (bắt buộc): Flutter
•	Database (tuỳ chọn): SQL Server, PostgreSQL, MySQL hoặc Firebase/Firestore
•	(Option cộng điểm): tích hợp AI/ML hoặc Deep Learning module
________________________________________
Chủ đề
•	Tự chọn
________________________________________
Yêu cầu kỹ thuật
Backend (.NET – bắt buộc)
•	ASP.NET Web API (RESTful API)
•	CRUD đầy đủ
•	Authentication & Authorization (JWT hoặc ASP.NET Identity)
•	Giao tiếp với DB qua Entity Framework Core hoặc ADO.NET
Frontend (Tùy chọn)
•	Web: HTML/CSS/JS hoặc React/Vue/Angular
•	Responsive Design
•	Gọi API từ Backend để hiển thị dữ liệu
Mobile App (Java Android Studio hoặc Flutter)
•	Giao diện thân thiện
•	Gọi API backend và xử lý dữ liệu
•	Tối thiểu: 3 role
Database (Tùy chọn)
•	Thiết kế sơ đồ ERD (nếu dùng relational DB)
•	Tạo dữ liệu mẫu (seed data)
•	Giao tiếp dữ liệu với backend
________________________________________
Yêu cầu bàn giao (Deliverables)
Ngoài việc hoàn thành đầy đủ chức năng của hệ thống, mỗi nhóm cần nộp đầy đủ các sản phẩm sau:
1. Source Code
•	Source code Backend
•	Source code Frontend
•	Source code Mobile App (Flutter)
•	File Database (Script SQL hoặc Migration)
•	README hướng dẫn cài đặt và sử dụng hệ thống
2. Quản lý mã nguồn
•	Sử dụng Git/GitHub trong suốt quá trình phát triển.
•	Có lịch sử commit rõ ràng, thể hiện quá trình phát triển của từng thành viên.
•	Có phân chia branch hợp lý (main, develop, feature,...).
3. Triển khai Docker & CI/CD (Bắt buộc)
Nhóm phải triển khai hệ thống bằng Docker và xây dựng quy trình CI/CD chạy trên môi trường Local.
Yêu cầu tối thiểu:
•	Dockerfile cho Backend.
•	Dockerfile cho Frontend (nếu có).
•	Docker Compose để chạy toàn bộ hệ thống.
•	Tự động build và khởi động toàn bộ hệ thống bằng Docker Compose.
•	Thiết lập quy trình CI/CD Local (GitHub Actions hoặc Jenkins hoặc Azure DevOps hoặc GitLab CI...) thực hiện tối thiểu:
o	Build source code
o	Restore dependencies
o	Build project
o	Chạy Unit Test (nếu có)
o	Build Docker Image
o	Deploy và chạy Docker Compose trên Local
4. Báo cáo Project (Bắt buộc)
Nộp báo cáo hoàn chỉnh dưới dạng PDF.
Báo cáo cần được trình bày đầy đủ theo mẫu Report số 7 do giảng viên cung cấp, bao gồm tối thiểu:
•	Giới thiệu đề tài
•	Phân tích yêu cầu
•	Thiết kế hệ thống
•	Thiết kế cơ sở dữ liệu (ERD)
•	Kiến trúc hệ thống
•	Thiết kế API
•	Các chức năng chính
•	Quy trình triển khai
•	Kết quả đạt được
•	Hướng phát triển
Lưu ý:
•	Mỗi hình minh họa phải có chú thích.
•	Có phần giải thích chi tiết cho từng hình.
•	Hình ảnh phải rõ nét và đúng nội dung trình bày.
5. Slide Báo cáo
Chuẩn bị Slide trình bày Project.
Nội dung tối thiểu:
•	Giới thiệu đề tài
•	Mục tiêu
•	Kiến trúc hệ thống
•	Công nghệ sử dụng
•	Thiết kế Database
•	Demo chức năng
•	Kết quả đạt được
•	Khó khăn
•	Hướng phát triển
Khuyến nghị:
•	15–20 slide.
•	Thời gian trình bày: 15–20 phút.
6. Demo hệ thống
Mỗi nhóm chuẩn bị:
•	Demo trực tiếp trên máy.
•	Video demo (5–10 phút) trong trường hợp phát sinh sự cố.
•	Hệ thống phải chạy được từ đầu bằng Docker Compose.
________________________________________
7. Tài liệu API
•	Cung cấp tài liệu API bằng Swagger/OpenAPI.
•	Mỗi API phải có mô tả rõ ràng.
•	Có ví dụ Request/Response.
8. Kiểm thử
•	Thực hiện Unit Test cho các module quan trọng.
•	Khuyến khích đạt tối thiểu 60% Code Coverage.
Tiêu chí đánh giá
Tiêu chí	Nội dung	Điểm
Chức năng backend	API chuẩn REST, bảo mật, kiểm thử	20
frontend/web/mobile	Giao diện, gọi API, UX/UI	20
Thiết kế CSDL	ERD, quan hệ logic, tối ưu truy vấn	15
Code sạch & tổ chức hợp lý	Tách lớp, mô-đun hoá, reusability	15
Tài liệu kỹ thuật & demo	Báo cáo + video demo	10
Có tích hợp AI	AI/ML	20
Tổng cộng		100 điểm
Ghi chú*: Nhóm cần chia công việc rõ ràng, sử dụng Git/GitHub để quản lý mã nguồn và ghi log quá trình làm việc.