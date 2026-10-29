<p align="center">
  <img src="public/favicon.svg" alt="VeggiePal" width="120" />
</p>

> Nền tảng hỗ trợ người ăn chay theo dõi sức khỏe, lên thực đơn, khám phá video nấu ăn, tìm quán chay và trò chuyện cùng trợ lý AI **VeggiePal**.

![React Version](https://img.shields.io/badge/React-19.x-61DAFB?style=flat-square&logo=react)
![Vite Version](https://img.shields.io/badge/Vite-8.x-646CFF?style=flat-square&logo=vite)
![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-v4-06B6D4?style=flat-square&logo=tailwindcss)

---

## 🔗 Liên kết dự án

- **Monorepo:** `VeggiePal-Microservice` gồm `frontend/` (web, thư mục này), `backend/` (Spring Boot Microservices) và `mobile/` (Flutter)
- **Frontend (bản gốc):** [huypg-bi/VeggiePal_FE](https://github.com/huypg-bi/VeggiePal_FE)
- **Backend (bản gốc):** [Phu0312/VeggiePal_BE](https://github.com/Phu0312/VeggiePal_BE.git)
- **Live Demo:** *(Đang cập nhật)*

---

## 📸 Giao diện ứng dụng (Screenshots)

*(Đang cập nhật — thêm ảnh vào `docs/images/` rồi bỏ comment bảng bên dưới)*

<!--
| Trang chủ (Landing Page) | Trợ lý AI VeggiePal |
| :---: | :---: |
| ![Landing Page](./docs/images/landing.png) | ![Chatbot](./docs/images/chatbot.png) |

| Lên thực đơn (Meal Planner) | Bản đồ quán chay (Map) |
| :---: | :---: |
| ![Meal Planner](./docs/images/meal-planner.png) | ![Restaurant Map](./docs/images/map.png) |
-->



---

## ✨ Tính năng nổi bật

- **🔐 Quản lý tài khoản (Authentication):** Đăng ký, đăng nhập xác thực JWT, bảo vệ đường dẫn riêng tư (Protected Routes).
- **👤 Hồ sơ cá nhân (Profile):** Quản lý thông tin cá nhân, cập nhật ảnh đại diện và đổi mật khẩu.
- **📊 Sức khỏe & Dị ứng (Nutrition):** Ghi nhận chiều cao/cân nặng, theo dõi lịch sử BMI, chọn danh mục thực phẩm dị ứng.
- **🥗 Thực đơn dinh dưỡng (Meal Planner):** AI lên thực đơn 7 ngày × 3 bữa theo mục tiêu giảm / duy trì / tăng cân (BE tự tính calo từ chỉ số sức khỏe, ngày sinh, giới tính, mức vận động, hoặc tự đặt mục tiêu riêng), nguyên liệu sẵn có và khẩu vị; xem theo ngày, đổi món, chuyển giữa các thực đơn đã lưu *(API thật; không còn dữ liệu mẫu)*.
- **🎥 Khám phá video (Videos):** Xem và đăng tải video nấu món chay (tệp .mp4 hoặc liên kết YouTube), phân trang và lọc theo danh mục, quản lý video cá nhân kèm kiểm duyệt tự động *(API thật)*. Tab "Bóc tách" ở trang Nội dung của tôi cho AI bóc tách nguyên liệu và các bước làm từ video (tệp ≤ 100MB, ≤ 30 phút, lịch sử `GET /ai/videos` theo lượt của gói thành viên). Ở trang xem video, nút "Bóc tách công thức AI" ở `VideoMetaHeader` và thẻ `AiSummaryCard` hiển thị công thức AI dùng chung cho video tải lên (`POST /ai/videos/process-existing`, xem công khai qua `GET /ai/videos/by-video/:videoId`, khách chưa đăng nhập vẫn xem được kết quả có sẵn) *(API thật)*.
- **📍 Bản đồ xanh (Map):** Tìm kiếm và xem danh sách các nhà hàng, quán ăn chay quanh vị trí của bạn trên bản đồ Mapbox *(API thật: location-service)*.
- **🤖 Trợ lý VeggiePal (AI Chatbot):** Giao diện hỏi đáp kiến thức dinh dưỡng chay, quản lý nhiều đoạn chat *(API thật: ai-service, có chế độ dùng thử cho khách)*.
- **🎨 Giao diện & Trải nghiệm:** Landing page hiện đại, hỗ trợ chuyển đổi chế độ Sáng/Tối (Light/Dark Mode).
- **💳 Gói thành viên & Thanh toán (Payment & Subscriptions):** Xem bảng giá các gói thành viên (FREE, PLUS, PRO), thanh toán qua cổng payOS VietQR, polling kiểm tra webhook kích hoạt gói tức thì, quản lý lịch sử thanh toán và thời hạn sử dụng *(API thật: payment-service)*. Trang thanh toán tự dựng `/checkout/:orderId`: FE tự vẽ mã VietQR bằng `qrcode.react`, đếm ngược hết hạn, polling trạng thái đơn, huỷ/tạo lại đơn.

---

## 💻 Công nghệ sử dụng (Tech Stack)

### Frontend Client
- **Core Framework:** React 19, Vite 8 (JavaScript / JSX)
- **Styling:** Tailwind CSS v4, shadcn/ui (`@base-ui/react`)
- **Routing:** React Router v7
- **State Management:** 
  - TanStack Query v5 *(Server State / Async Data)*
  - Zustand v5 *(Global Auth State, Theme State)*
  - qrcode.react *(vẽ mã VietQR ở trang `/checkout/:orderId`)*
- **Form & Validation:** React Hook Form + Zod Schema
- **HTTP Client:** Axios
- **Icons:** Lucide React
- **Code Quality & Testing:** ESLint 10, `node:test`

### Backend Integration
- Kết nối hệ thống **Spring Boot Microservices (Java 21)** thông qua API Gateway tại `http://localhost:8080/api`.

---

## 🛠️ Yêu cầu hệ thống (Prerequisites)

- **Node.js:** `^20.19.0` hoặc `>=22.12.0`
- **Package Manager:** `npm` (đi kèm Node.js)
- **Backend Service:** API Gateway (`backend/api-gateway`) chạy tại `http://localhost:8080` *(Cần thiết nếu muốn trải nghiệm đầy đủ API thật; gateway đã cho phép CORS từ `http://localhost:*`)*

---

## ⚙️ Hướng dẫn cài đặt & Khởi chạy (Getting Started)

### 1. Vào thư mục frontend
```bash
cd frontend
```

### 2. Cài đặt thư viện
```bash
npm install
```

### 3. Cấu hình biến môi trường
Copy `.env.example` thành `.env` trong thư mục `frontend/` (file đã được `.gitignore`, không commit) rồi điền giá trị:

```env
VITE_VEGGIEPAL_API_BASE_URL=http://localhost:8080/api
VITE_GOOGLE_CLIENT_ID=<oauth-client-id>.apps.googleusercontent.com
```

| Biến | Mô tả |
| :--- | :--- |
| `VITE_VEGGIEPAL_API_BASE_URL` | Base URL của API Gateway (đã gồm `/api`) |
| `VITE_GOOGLE_CLIENT_ID` | Google OAuth Client ID cho đăng nhập Google; phải trùng `GOOGLE_CLIENT_ID` của identity-service |

### 4. Khởi chạy
```bash
npm run dev
```
Giao diện chạy tại: http://localhost:5173

| Lệnh | Mô tả |
| :--- | :--- |
| `npm run dev` | Chạy môi trường phát triển |
| `npm run build` | Build production vào thư mục `dist/` |
| `npm run preview` | Chạy thử bản build |
| `npm run lint` | Kiểm tra code với ESLint |
| `npm test` | Chạy test tạm (`*.test.js`). Repo không giữ file test lâu dài: viết để kiểm tra, test xong thì xóa |

---

## 📁 Cấu trúc thư mục

```text
src/
├── app/            # App, provider (Query + Router), routes
├── components/ui/  # Component shadcn/ui (button, dialog, dropdown-menu, select ...)
├── features/       # auth, home, meal-planner, payment, profile, video, restaurant-map, chatbot
├── lib/            # queryClient, schema zod, cn
├── shared/         # apiClient (axios), Reveal, ThemeToggle, ScrollToTop (về đầu trang khi đổi route), SelectField (dropdown chọn giá trị), themeStore
└── styles/         # globals.css (Tailwind + design token)
docs/TECH_STACK.md  # Quy ước công nghệ & UI
```

Alias import: `@/` trỏ tới `src/`.

---

## 🔌 API chính

Gọi qua API Gateway, response dạng `{ code, message, result }`, cần JWT (trừ `/auth/*`).

| Method | Endpoint | Mô tả |
| :--- | :--- | :--- |
| `POST` | `/auth/login` | Đăng nhập |
| `POST` | `/auth/register` | Đăng ký |
| `POST` | `/auth/google` | Đăng nhập / đăng ký bằng Google (gửi `idToken`) |
| `GET` / `PATCH` | `/users/me` | Xem / sửa hồ sơ (họ tên, số điện thoại, ngày sinh, giới tính, mức vận động) |
| `PUT` | `/users/me/password` | Đổi mật khẩu |
| `POST` | `/users/me/avatar` | Tải ảnh đại diện |
| `GET` | `/nutrition/allergens` | Danh mục dị ứng |
| `GET` / `PUT` | `/nutrition/me/allergies` | Xem / cập nhật dị ứng |
| `GET` / `POST` | `/nutrition/me/health-records` | Lịch sử / ghi chỉ số sức khỏe |
| `GET` | `/nutrition/me/health-records/latest` | Chỉ số sức khỏe mới nhất |
| `PUT` | `/nutrition/me/health-records/:id` | Sửa một bản ghi chỉ số sức khỏe trong lịch sử |
| `GET` | `/ai/admin/monitoring/summary`, `/logs/search`, `/models`, `/limits` | Giám sát AI (chỉ ADMIN): tổng hợp, nhật ký, model, giới hạn |
| `GET` / `PUT` / `DELETE` | `/ai/admin/moderation`, `/ai/admin/moderation/:id` | Kiểm duyệt nội dung (chỉ ADMIN): hàng đợi / duyệt hoặc từ chối / bỏ qua ca (nội dung gốc không đổi trạng thái) |
| `GET` | `/admin/payments/summary`, `/statistics`, `/revenue`, `/orders`, `/orders/:id` | Thống kê thanh toán (chỉ ADMIN): tổng quan, phân bố, doanh thu theo ngày / tháng, danh sách và chi tiết đơn hàng |
| `GET` | `/ai/meal-plans/nutrition-target` | Mục tiêu calo / macro BE tính theo hồ sơ cho `goalType` (`LOSE` / `MAINTAIN` / `GAIN`), hiện ở form tạo thực đơn |
| `GET` | `/ai/meal-plans/:id` | Một thực đơn (lấy mới khi mở hộp thoại "Lịch sử") |
| `GET` | `/ai/meal-plans/favorites`, `/ai/meal-plans/favorites/:id` | Danh sách thực đơn yêu thích (phân trang) / một thực đơn yêu thích |
| `GET` | `/ai/meal-plans/:id/versions`, `/ai/meal-plans/:id/versions/:version` | Lịch sử phiên bản / nội dung một phiên bản cũ |
| `GET` | `/payments/plans` | Danh sách gói thành viên (công khai) |
| `POST` | `/payments/checkout` | Tạo đơn thanh toán payOS (gói PLUS / PRO) |
| `GET` | `/payments/orders/:id` | Chi tiết đơn thanh toán theo ID |
| `POST` | `/payments/orders/:id/cancel` | Huỷ đơn thanh toán PENDING (`cancelOrder`), trả đơn với status CANCELLED |
| `GET` | `/payments/history` | Lịch sử giao dịch của người dùng |
| `GET` | `/subscriptions/me` | Thông tin gói thành viên hiện tại và hạn dùng |
