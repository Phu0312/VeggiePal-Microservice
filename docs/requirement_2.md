# HƯỚNG DẪN TRIỂN KHAI VÀ ĐỀ CƯƠNG BÁO CÁO TASK 2

---

## I. MỤC TIÊU TỔNG QUAN CỦA TASK 2

Task 2 tập trung vào ba giai đoạn chính:
1. **Implementation:** Hiện thực hóa hệ thống.
2. **Experimentation:** Thử nghiệm hệ thống.
3. **Evaluation:** Đánh giá tính khả thi của giải pháp.

---

## II. CÔNG VIỆC CẦN THỰC HIỆN

### 2.1. Thiết kế và xây dựng cơ sở dữ liệu (Database)

#### a. Công việc cần thực hiện
- **Thiết kế sơ đồ ERD** (*Entity Relationship Diagram*) và **sơ đồ quan hệ** (*Relational Schema*) đáp ứng đầy đủ các nghiệp vụ, chức năng đã xác định tại Task 1.
- **Cài đặt cơ sở dữ liệu:**
  - *Cơ sở dữ liệu quan hệ:* PostgreSQL, MySQL.
  - *Cơ sở dữ liệu NoSQL:* MongoDB.
- **Viết các script khởi tạo:**
  - **DDL:** Định nghĩa cấu trúc dữ liệu.
  - **DML:** Tạo và thao tác dữ liệu mẫu phục vụ kiểm thử.

#### b. Báo cáo và đánh giá
Lập bảng thống kê tiến độ thực hiện các nghiệp vụ Database, bao gồm:
- Danh sách nghiệp vụ đã hoàn thành.
- Danh sách nghiệp vụ chưa hoàn thành hoặc gặp rào cản.
- **Phân tích nguyên nhân:**
  - Truy vấn phức tạp.
  - Cấu trúc dữ liệu chưa được tối ưu.
  - Xung đột ràng buộc dữ liệu.
- Giải pháp khắc phục cụ thể và thời hạn hoàn thành.

---

### 2.2. Triển khai DevOps, CI/CD và Microservices

#### a. Xây dựng kiến trúc Microservices và Dockerization
- Đóng gói từng service độc lập thành Docker Container.
- Xây dựng các file:
  - `Dockerfile`
  - `docker-compose.yml`
- Cấu hình kết nối mạng nội bộ giữa các container và API Gateway.

#### b. Thiết lập quy trình CI/CD bằng GitHub Actions
Cấu hình pipeline thực hiện các bước:
1. Code Linting
2. Build
3. Test
4. Automated Unit Test
5. Integration Test
6. Deploy hoặc Container Registry

> **Lưu ý:** Đảm bảo mọi commit hoặc pull request trên các nhánh chính như `main` và `develop` đều chạy qua pipeline.

#### c. Thử nghiệm và đánh giá
- Lập bảng ghi nhận kết quả Test Cases.
- Thống kê tổng số test case và tỷ lệ Pass/Fail.
- Thu thập nhật ký GitHub Actions.
- Chụp ảnh màn hình và trích xuất log chứng minh pipeline chạy thành công, bao gồm:
  - Thời gian build.
  - Kết quả kiểm thử tự động.
  - Trạng thái pipeline.

---

### 2.3. Triển khai và đóng gói Model AI (Self-Hosted Model Integration)

#### a. Yêu cầu kỹ thuật
- Sử dụng mô hình AI tự triển khai (*Self-hosted / In-house*).
- **Không gọi trực tiếp các API thương mại trả phí** như OpenAI API, Claude API hoặc Gemini API nhằm tối ưu chi phí token và làm chủ công nghệ.

**Các công việc cần thực hiện:**
- Đóng gói model AI đã được huấn luyện hoặc sử dụng mô hình mã nguồn mở đã được huấn luyện trước (*Pre-trained Open-Source Model*).
- *Các mô hình tham khảo:* Llama, YOLO, Whisper, BERT.
- Triển khai model trong Docker Container.
- Xây dựng API Wrapper bằng FastAPI, Flask hoặc Triton Inference Server để cung cấp khả năng truy vấn cho các service khác.

#### b. Nhiệm vụ cụ thể
- **Tối ưu hóa quá trình suy luận của mô hình (Model Inference):**
  - Quantization.
  - ONNX Export.
- **Đánh giá hiệu năng của Docker Model AI:**
  - Thời gian phản hồi (*Latency*, ms).
  - Mức tiêu thụ RAM.
  - Mức sử dụng GPU/CPU.

---

### 2.4. Triển khai phương pháp đề xuất, thực nghiệm và đánh giá

#### a. Hiện thực hóa phương pháp đề xuất (Proposed Method)
Triển khai giải pháp kỹ thuật chính đã đề xuất tại Task 1 vào phần mềm.

#### b. Thử nghiệm và thu thập số liệu
- Thực hiện thử nghiệm trên bộ dữ liệu kiểm thử (*Test Dataset*).
- Hoặc sử dụng các kịch bản người dùng thực tế.

#### c. Phân tích kết quả và các trường hợp thất bại (Failure Cases)
- **Trình bày các chỉ số đo lường phù hợp:**
  - Accuracy
  - Precision
  - Recall
  - F1-score
  - Response Time
  - Throughput
- **Phân tích các trường hợp hệ thống hoặc model xử lý sai / lỗi:**
  - Dữ liệu nhiễu.
  - Các trường hợp biên (*Edge Cases*) chưa được xử lý.
  - Giới hạn phần cứng.

#### d. Trực quan hóa kết quả
Xây dựng các biểu đồ và đồ thị phù hợp:
- Confusion Matrix.
- ROC Curve.
- Biểu đồ so sánh thời gian xử lý.
- Biểu đồ phân bổ lỗi.

#### e. Kết luận về tính khả thi
Dựa trên kết quả thực nghiệm để đưa ra đánh giá khách quan về tính khả thi của giải pháp.

---

## III. NỘI DUNG FILE THUYẾT TRÌNH TASK 2

### Nội dung 1. Introduction
- Tên đề tài.
- Danh sách sinh viên thực hiện.
- Giảng viên hướng dẫn.
- Nội dung báo cáo: Task 2.

### Nội dung 2. Tóm tắt kết quả Task 1 và mục tiêu Task 2
- Tóm tắt ngắn gọn Problem từ Task 1.
- Tóm tắt Proposed Method từ Task 1.
- Trình bày các mục tiêu và nội dung của Task 2.

### Nội dung 3. Thiết kế và triển khai cơ sở dữ liệu (Database)
- Sơ đồ tổng quan ERD.
- Kiến trúc dữ liệu.
- Các công nghệ Database được lựa chọn.
- Lý do lựa chọn công nghệ.

### Nội dung 4. Thống kê tiến độ triển khai dữ liệu theo nghiệp vụ
- Bảng thống kê các nghiệp vụ đã hoàn thành.
- Bảng thống kê các nghiệp vụ chưa hoàn thành.
- Phân tích nguyên nhân.
- Đề xuất phương án khắc phục.

### Nội dung 5. Kiến trúc hệ thống và Microservices
- Sơ đồ kiến trúc Microservices.
- Cấu hình Docker Container cho từng service.
- Cách các service giao tiếp với nhau và với API Gateway.

### Nội dung 6. Triển khai DevOps và quy trình CI/CD
- Sơ đồ workflow GitHub Actions.
- Quy trình build, test và deploy.
- Hình ảnh nhật ký GitHub Actions chạy thành công.

### Nội dung 7. Báo cáo kiểm thử tự động (Testing Report)
- Bảng thống kê số lượng Test Cases.
- Phân loại: Unit Test, Integration Test.
- Tỷ lệ Pass/Fail.
- Đánh giá độ ổn định của hệ thống.

### Nội dung 8. Đóng gói và tích hợp Model AI trong Docker
- Kiến trúc đóng gói Model AI.
- Mô hình Self-hosted Local Model.
- API Wrapper.
- Thông số phần cứng.
- Mức tiêu thụ RAM, CPU và GPU.
- Thời gian phản hồi (Latency).

### Nội dung 9. Hiện thực hóa phương pháp đề xuất (Proposed Method)
- Luồng xử lý chi tiết của thuật toán hoặc phương pháp cốt lõi.
- Các kỹ thuật tối ưu đã áp dụng.
- Mô tả cách tích hợp phương pháp vào hệ thống.

### Nội dung 10. Thiết lập giai đoạn thực nghiệm (Experimental Setup)
- Mô tả bộ dữ liệu thử nghiệm (Dataset).
- Hoặc mô tả các kịch bản thử nghiệm.
- Trình bày các chỉ số đo lường hiệu năng (Metrics).

### Nội dung 11. Trực quan hóa kết quả thực nghiệm (Visualized Results)
- Biểu đồ hoặc đồ thị thể hiện hiệu năng: Accuracy, Speed, Throughput.
- Bảng so sánh giữa mục tiêu đề ra và kết quả thực tế đạt được.

### Nội dung 12. Phân tích các trường hợp lỗi (Failure Cases Analysis)
- Trích xuất các mẫu hoặc trường hợp hệ thống/model xử lý thất bại.
- Phân tích nguyên nhân gốc rễ (*Root Cause Analysis*).
- Đề xuất hướng khắc phục.

### Nội dung 13. Đánh giá tính khả thi của sản phẩm cuối cùng
- Phân tích điểm mạnh của giải pháp.
- Phân tích điểm yếu hiện tại.
- Đánh giá khả năng phát triển thành sản phẩm hoàn chỉnh (*Feasibility Assessment*).

### Nội dung 14. Kế hoạch tiếp theo (Task 3 / Hoàn thiện sản phẩm)
- Các công việc cần cải tiến dựa trên Failure Cases.
- Lịch trình hoàn thiện giao diện UI/UX.
- Kế hoạch đóng gói sản phẩm hoàn chỉnh.

### Nội dung 15. Cảm ơn và Q&A
- Lời cảm ơn giảng viên và người tham dự.
- Phần hỏi đáp (*Questions & Answers*).

---

## IV. GỢI Ý TRÌNH BÀY TRÊN GOOGLE COLAB

Để trình bày nội dung rõ ràng trên Google Colab:

1. **Sử dụng ô Text** để trình bày tiêu đề và nội dung Markdown.
2. **Phân cấp tiêu đề:** Sử dụng `#` cho tiêu đề chính, `##` cho tiêu đề cấp hai và `###` cho tiêu đề cấp ba.
3. **Trình bày dữ liệu:** Sử dụng bảng Markdown để trình bày tiến độ, kết quả kiểm thử và các chỉ số đánh giá.
4. **Trực quan hóa:** Sử dụng ô **Code** để chạy Python tạo biểu đồ, bảng số liệu và hình ảnh minh họa.
5. **Tính chính xác:** Chỉ đưa số liệu thực nghiệm sau khi đã chạy thử nghiệm và thu thập kết quả thực tế.