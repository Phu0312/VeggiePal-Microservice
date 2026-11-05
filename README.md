# VeggiePal - Hệ Sinh Thái Dinh Dưỡng & Ẩm Thực Chay Toàn Diện

> **Đồ án môn PRM393 - Đại học FPT**  
> Nền tảng microservices toàn diện hỗ trợ lối sống ăn chay khoa học: Lập thực đơn AI 7 ngày, Trợ lý Chatbot AI, Bóc tách dinh dưỡng video AI, Kiểm duyệt nội dung tự động, Bản đồ quán chay thông minh, Mạng xã hội ẩm thực và Cổng thanh toán thành viên PayOS VietQR.

---

## Mục lục

1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Kiến trúc hệ thống (Architecture)](#2-kiến-trúc-hệ-thống-architecture)
3. [Cấu trúc mã nguồn (Monorepo)](#3-cấu-trúc-mã-nguồn-monorepo)
4. [Yêu cầu môi trường (Prerequisites)](#4-yêu-cầu-môi-trường-prerequisites)
5. [Cơ sở dữ liệu & File Script SQL Khởi tạo](#5-cơ-sở-dữ-liệu--file-script-sql-khởi-tạo)
6. [Cấu hình biến môi trường (`.env`)](#6-cấu-hình-biến-môi-trường-env)
7. [Hướng dẫn cài đặt & Khởi chạy hệ thống](#7-hướng-dẫn-cài-đặt--khởi-chạy-hệ-thống)
   - [Cách 1: Khởi chạy nhanh toàn bộ Backend qua Docker Compose](#cách-1-khởi-chạy-nhanh-toàn-bộ-backend-qua-docker-compose-khuyến-nghị)
   - [Cách 2: Khởi chạy Backend thủ công (Local Development)](#cách-2-khởi-chạy-backend-thủ-công-local-development)
   - [Cách 3: Khởi chạy Web Client (React 19 + Vite)](#cách-3-khởi-chạy-web-client-react-19--vite)
   - [Cách 4: Khởi chạy Mobile App (Flutter)](#cách-4-khởi-chạy-mobile-app-flutter)
   - [Cách 5: Thiết lập Local AI Runner (Tùy chọn)](#cách-5-thiết-lập-local-ai-runner-tùy-chọn)
8. [Tài khoản kiểm thử & Phân quyền](#8-tài-khoản-kiểm-thử--phân-quyền)
9. [Hướng dẫn sử dụng các luồng nghiệp vụ chính](#9-hướng-dẫn-sử-dụng-các-luồng-nghiệp-vụ-chính)
10. [Tài liệu API & Swagger UI](#10-tài-liệu-api--swagger-ui)
11. [Xử lý sự cố thường gặp (Troubleshooting)](#11-xử-lý-sự-cố-thường-gặp-troubleshooting)
12. [Quy trình CI/CD Tự động hóa](#12-quy-trình-cicd-tự-động-hóa)

---

## 1. Tổng quan dự án

**VeggiePal** là giải pháp công nghệ số nhằm giải quyết triệt để các rào cản của người bắt đầu và duy trì lối sống ăn chay: thiếu hụt vi chất, khó lên thực đơn đủ chất, dị ứng thực phẩm, thiếu ý tưởng nấu nướng và khó tìm quán chay phù hợp.

### Các phân hệ cốt lõi:
- **Quản lý Định danh & Tài khoản (Identity Service):** Xác thực JWT HS256, làm mới phiên tự động (Refresh Token), đăng nhập Google OAuth2, xác minh email và đặt lại mật khẩu qua mã OTP 6 số.
- **Sức khỏe & Dinh dưỡng Cá nhân hóa (Nutrition Service):** Theo dõi chiều cao, cân nặng, lịch sử BMI, quản lý danh mục dị ứng cá nhân, ghi nhật ký ăn uống (Food Log) và nhật ký thể chất/nước uống (Daily Wellness Log).
- **Trí tuệ nhân tạo (AI Service):**
  - **Lập thực đơn 7 ngày (Meal Planner):** Tạo kế hoạch 21 bữa ăn tự động từ kho công thức chuẩn, bám sát nhu cầu calo/macro (BMR/TDEE), tuyệt đối loại trừ các chất gây dị ứng đã khai báo.
  - **Trợ lý Chatbot AI:** Tư vấn dinh dưỡng chay chuyên sâu, hỗ trợ lưu lịch sử hội thoại, quản lý hạn mức theo gói hội viên.
  - **Kiểm duyệt tự động (AI Moderation):** Quét nội dung bài viết và video để ngăn chặn spam, ngôn từ độc hại và nội dung không phù hợp với tiêu chuẩn ăn chay.
- **Cộng đồng & Truyền thông (Blog & Video Service):** Đăng tải bài viết, video nấu ăn (YouTube/Cloudinary), hệ thống bình luận đa cấp, bình chọn (Upvote/Downvote), theo dõi tác giả và thử thách 7 ngày ăn chay.
- **Bách khoa Công thức & Nguyên liệu (Recipe Service):** Tra cứu công thức, tự động tính toán tổng năng lượng và dinh dưỡng (Protein, Carbs, Fat, Fiber) trên từng khẩu phần.
- **Bản đồ Quán ăn chay (Location Service):** Định vị quán chay gần người dùng dựa trên tọa độ GPS thực tế (`ST_Distance_Sphere`), tìm kiếm theo từ khóa và phân loại thuần chay (Vegan Only).
- **Thanh toán & Gói thành viên (Payment Service):** Tích hợp cổng thanh toán VietQR tự động qua **PayOS**, quản lý các gói **FREE**, **PLUS** (29.000 VNĐ), **PRO** (59.000 VNĐ) và tự động đồng bộ hạn mức AI.

---

## 2. Kiến trúc hệ thống (Architecture)

Hệ thống được thiết kế theo kiến trúc **Microservices** hiện đại, áp dụng mẫu **Database-per-Service**:
- Mọi truy vấn từ Web và Mobile Client đều đi qua **API Gateway** duy nhất.
- Các service độc lập về cơ sở dữ liệu (7 database schemas riêng biệt trên MySQL 8.4), giao tiếp nội bộ qua REST đồng bộ với token bảo mật `INTERNAL_SERVICE_TOKEN`.
- Webhook từ PayOS được chuyển tiếp an toàn vào Gateway thông qua **Ngrok Tunnel**.

```text
  ┌────────────────────────────────────────────────────────┐
  │                 CLIENT APPLICATIONS                    │
  │   - Web App (React 19, Vite, Tailwind CSS v4)          │
  │   - Mobile App (Flutter / Dart, Dio, Provider)         │
  └───────────────────────────┬────────────────────────────┘
                              │
                    HTTP REST Requests (Port 9080)
                              │
  ┌───────────────────────────▼────────────────────────────┐
  │              API GATEWAY (Spring Cloud Gateway)        │
  │     Routing, CORS, Centralized Swagger UI (:8080)      │
  └─────┬───────┬────────┬────────┬────────┬───────┬───────┘
        │       │        │        │        │       │
  ┌─────▼─┐ ┌───▼──┐ ┌───▼──┐ ┌───▼──┐ ┌───▼──┐ ┌─▼────┐ ┌──▼─────┐
  │Identity│ │Nutri-│ │Blog  │ │Recipe│ │Loca- │ │AI   │ │Payment │
  │Service │ │tion  │ │Service│ │Service│ │tion  │ │Ser- │ │Service │
  │ :8081  │ │ :8082│ │ :8083│ │ :8084│ │ :8085│ │vice │ │ :8087  │
  └───┬────┘ └───┬──┘ └───┬──┘ └───┬──┘ └───┬──┘ │:8086│ └───┬────┘
      │          │        │        │        │    └──┬──┘      │
      │          │        │        │        │       │         │
  ┌───▼──────────▼────────▼────────▼────────▼───────▼─────────▼────┐
  │                       MySQL 8.4 DATABASE                       │
  │  7 Schemas: veggiepal_identity, veggiepal_nutrition,           │
  │             veggiepal_blog,     veggiepal_recipe,              │
  │             veggiepal_location, veggiepal_ai,                  │
  │             veggiepal_payment                                  │
  └────────────────────────────────────────────────────────────────┘
```

### Danh mục Service & Cổng truy cập:

| Thành phần | Port Container | Port Host (Máy thật) | Cơ sở dữ liệu (Schema) | Trách nhiệm chính |
|---|:---:|:---:|---|---|
| **API Gateway** | `8080` | `9080` | — | Định tuyến, CORS, xác thực tập trung, gộp Swagger UI |
| **Identity Service** | `8081` | *Nội bộ* | `veggiepal_identity` | Tài khoản, JWT, Google OAuth, hồ sơ, OTP |
| **Nutrition Service** | `8082` | *Nội bộ* | `veggiepal_nutrition` | Chỉ số BMI, dị ứng, nhật ký ăn uống & thể chất |
| **Blog Service** | `8083` | *Nội bộ* | `veggiepal_blog` | Bài viết, video nấu ăn, bình luận, vote, challenge |
| **Recipe Service** | `8084` | *Nội bộ* | `veggiepal_recipe` | Kho công thức, nguyên liệu, tính toán dinh dưỡng |
| **Location Service** | `8085` | *Nội bộ* | `veggiepal_location` | Định vị GPS nhà hàng chay, tìm kiếm quán gần bạn |
| **AI Service** | `8086` | *Nội bộ* | `veggiepal_ai` | Thực đơn AI 7 ngày, Chatbot, AI Moderation |
| **Payment Service** | `8087` | *Nội bộ* | `veggiepal_payment` | Gói thành viên, đơn hàng PayOS VietQR, Webhook |
| **MySQL DBMS** | `3306` | `4307` | *7 schemas* | Lưu trữ toàn bộ dữ liệu hệ sinh thái |
| **Ngrok Inspector** | `4040` | `5041` | — | Kiểm tra lưu lượng Webhook từ PayOS |

*(Ghi chú: Khi chạy Docker, các service backend được cô lập trong mạng `veggiepal-prm-backend`, chỉ Gateway `9080`, MySQL `4307` và Ngrok `5041` được mở ra ngoài host).*

---

## 3. Cấu trúc mã nguồn (Monorepo)

```text
VeggiePal-Microservice/
├── init_database.sql             # Script SQL tổng hợp khởi tạo 7 database & 36 bảng + seed data
├── README.md                     # Hướng dẫn chi tiết cài đặt và sử dụng hệ thống
├── backend/                      # Chứa mã nguồn 8 microservices (Spring Boot 4.1.1, Java 21)
│   ├── .env.example              # Mẫu cấu hình môi trường cho Backend
│   ├── docker-compose.yml        # Docker Compose chạy toàn bộ backend stack
│   ├── docker-compose.infra.yml  # Docker Compose chỉ chạy MySQL + Ngrok (cho local dev)
│   ├── api-gateway/              # API Gateway (Spring Cloud Gateway Server WebMVC)
│   ├── identity-service/         # Quản lý người dùng, phân quyền, bảo mật
│   ├── nutrition-service/        # Quản lý dị ứng, sức khỏe, nhật ký dinh dưỡng
│   ├── blog-service/             # Mạng xã hội bài viết, video, bình luận, thử thách
│   ├── recipe-service/           # Quản lý món ăn, nguyên liệu, công thức chế biến
│   ├── location-service/         # Định vị và tìm kiếm quán ăn chay
│   ├── ai-service/               # Lập thực đơn, chatbot AI, kiểm duyệt nội dung
│   ├── payment-service/          # Thanh toán VietQR qua cổng PayOS
│   └── ai-inference/             # Cấu hình & script chạy local model AI (Qwen/llama.cpp)
├── frontend/                     # Ứng dụng Web Client (React 19, Vite, Tailwind CSS v4)
│   ├── .env.example              # Mẫu cấu hình môi trường cho Web
│   ├── src/                      # Toàn bộ mã nguồn React (App, Features, Components)
│   └── package.json              # Quản lý thư viện npm
└── mobile/                       # Ứng dụng Di động (Flutter 3.x, Dart)
    ├── .env.example              # Mẫu cấu hình môi trường cho Mobile
    ├── lib/                      # Toàn bộ mã nguồn Flutter (Core, Features, Navigation)
    └── pubspec.yaml              # Quản lý dependencies Flutter
```

---

## 4. Yêu cầu môi trường (Prerequisites)

Để cài đặt và vận hành hệ thống thuận lợi, máy tính của bạn cần cài đặt:

| Công cụ | Phiên bản khuyến nghị | Mục đích sử dụng |
|---|---|---|
| **Git** | Mới nhất | Clone và quản lý mã nguồn |
| **Docker & Docker Compose** | Docker Desktop v24+, Compose v2+ | Khởi chạy toàn bộ backend và cơ sở dữ liệu |
| **Node.js** | `>= 20.19.0` hoặc `>= 22.12.0` | Chạy ứng dụng Web Frontend |
| **JDK (Java Development Kit)** | `OpenJDK 21` | Chỉ cần nếu muốn chạy backend thủ công hoặc build Maven cục bộ |
| **Maven** | `3.9+` (hoặc dùng `mvnw`) | Build các module backend |
| **Flutter SDK** | `>= 3.13.2` | Biên dịch và chạy ứng dụng Mobile |
| **Android Studio / Xcode** | Mới nhất | Chạy máy ảo Android Emulator hoặc iOS Simulator |

---

## 5. Cơ sở dữ liệu & File Script SQL Khởi tạo

Hệ thống sử dụng **7 schemas riêng biệt** trên cùng một máy chủ MySQL:
1. `veggiepal_identity`: 5 bảng (`users`, `user_otps`, `refresh_tokens`, `user_favorites`, `user_badges`).
2. `veggiepal_nutrition`: 5 bảng (`allergens`, `user_allergies`, `health_records`, `food_logs`, `daily_wellness_logs`).
3. `veggiepal_blog`: 7 bảng (`categories`, `blogs`, `videos`, `comments`, `content_votes`, `user_follows`, `user_challenges`).
4. `veggiepal_recipe`: 5 bảng (`recipes`, `ingredients`, `recipe_ingredients`, `recipe_steps`, `recipe_likes`).
5. `veggiepal_location`: 1 bảng (`vegetarian_restaurants`).
6. `veggiepal_ai`: 10 bảng (`ai_conversations`, `ai_chat_messages`, `ai_daily_quotas`, `ai_usage_logs`, `ai_moderation_cases`, `ai_meal_plans`, `ai_meal_plan_favorites`, `ai_meal_plan_versions`, `ai_video_jobs`, `ai_guest_sessions` + bảng lịch sử `flyway_schema_history`).
7. `veggiepal_payment`: 3 bảng (`subscription_plans`, `user_subscriptions`, `payment_orders`).

Tổng cộng: **36 bảng**.

### File `init_database.sql` ở thư mục gốc:
Để giúp việc cài đặt nhanh chóng và không phụ thuộc vào thứ tự khởi động dịch vụ, file **`init_database.sql`** đã được tạo sẵn ở thư mục ngoài cùng cấp với `frontend`, `backend`, `mobile`. File này chứa toàn bộ DDL (CREATE DATABASE, CREATE TABLE, INDEXES, CONSTRAINTS) và toàn bộ dữ liệu mẫu (Seed Data) chuẩn:
- 3 tài khoản mặc định (Admin, User 1, User 2).
- 32 danh mục dị ứng phổ biến chuẩn y khoa.
- Cây danh mục ẩm thực, bài viết blog mẫu, bình luận và lượt vote.
- 87 nguyên liệu thực vật chi tiết vi chất, 115 công thức món chay kèm 508 định lượng và 363 bước nấu.
- 100 nhà hàng chay thực tế có tọa độ địa lý GPS tại Việt Nam.
- 3 gói dịch vụ thành viên PayOS (FREE, PLUS, PRO).
- Bảng lịch sử Flyway để `ai-service` đồng bộ ngay lập tức.

### Cách nạp dữ liệu thủ công bằng file `init_database.sql`:

Nếu bạn muốn tạo mới hoặc khôi phục toàn bộ database:

**Trường hợp 1: Sử dụng Docker MySQL của dự án (Port 4307):**
```powershell
# Chạy từ thư mục gốc của project
Get-Content init_database.sql | docker exec -i veggiepal-prm-mysql mysql -u root -p"VeggiePal@2026_SecureKey"
```

**Trường hợp 2: Sử dụng MySQL trên máy host cục bộ (Port 3306):**
```powershell
mysql -h 127.0.0.1 -P 3306 -u root -p < init_database.sql
```

---

## 6. Cấu hình biến môi trường (`.env`)

Trước khi khởi chạy, cần tạo các file `.env` từ các file `.env.example`.

### 6.1. Cấu hình Backend (`backend/.env`)

Tại thư mục `backend/`:
```powershell
Copy-Item .env.example .env
```

Nội dung quan trọng trong `backend/.env`:

```dotenv
# --- CẤU HÌNH CƠ SỞ DỮ LIỆU ---
DB_USERNAME=root
DB_PASSWORD=VeggiePal@2026_SecureKey
PRM_MYSQL_HOST_PORT=4307

# --- BẢO MẬT & GATEWAY ---
PRM_GATEWAY_HOST_PORT=9080
JWT_SECRET=veggiepal-super-secret-key-must-be-at-least-32-characters-long
INTERNAL_SERVICE_TOKEN=internal-veggiepal-secret-token-for-inter-service-calls-2026

# --- NGROK (Bắt buộc cho Webhook PayOS) ---
NGROK_AUTHTOKEN=your_ngrok_token_here
PRM_NGROK_INSPECTOR_HOST_PORT=5041

# --- CLOUDINARY (Lưu trữ ảnh & video) ---
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# --- PAYOS (Cổng thanh toán) ---
PAYOS_CLIENT_ID=your_payos_client_id
PAYOS_API_KEY=your_payos_api_key
PAYOS_CHECKSUM_KEY=your_payos_checksum_key

# --- GOOGLE OAUTH (Tùy chọn) ---
GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
```

### 6.2. Cấu hình Web (`frontend/.env`)

Tại thư mục `frontend/`:
```powershell
Copy-Item .env.example .env
```

Nội dung trong `frontend/.env`:
```dotenv
VITE_VEGGIEPAL_API_BASE_URL=http://localhost:9080/api
VITE_GOOGLE_CLIENT_ID=your_google_client_id.apps.googleusercontent.com
VITE_MAPBOX_TOKEN=pk.your_mapbox_token_here
VITE_MAPBOX_STYLE=mapbox://styles/mapbox/streets-v12
```

### 6.3. Cấu hình Mobile (`mobile/.env`)

Tại thư mục `mobile/`:
```powershell
Copy-Item .env.example .env
```

Nội dung trong `mobile/.env`:
```dotenv
# Với máy ảo Android Emulator: dùng 10.0.2.2 thay cho localhost
API_BASE_URL=http://10.0.2.2:9080/api

# Với iOS Simulator hoặc máy thật cùng mạng LAN:
# API_BASE_URL=http://localhost:9080/api
# API_BASE_URL=http://192.168.1.xxx:9080/api
```

---

## 7. Hướng dẫn cài đặt & Khởi chạy hệ thống

### Cách 1: Khởi chạy nhanh toàn bộ Backend qua Docker Compose (Khuyến nghị)

Đây là cách nhanh nhất và ổn định nhất để dựng toàn bộ 8 services backend + MySQL 8.4 + Ngrok.

**Bước 1:** Chuẩn bị file `.env` tại thư mục `backend/` như hướng dẫn ở mục 6.1.

**Bước 2:** Khởi chạy toàn bộ stack Docker:
```powershell
Set-Location backend
docker compose --project-name veggiepal-prm up -d --build --wait --wait-timeout 300
```

**Bước 3:** Kiểm tra trạng thái các container:
```powershell
docker compose --project-name veggiepal-prm ps
```
Tất cả 10 containers (`mysql`, `ngrok`, `identity-service`, `nutrition-service`, `blog-service`, `recipe-service`, `location-service`, `ai-service`, `payment-service`, `api-gateway`) phải ở trạng thái `running` (healthy).

**Bước 4:** Kiểm tra Swagger UI tập trung:
Mở trình duyệt truy cập: <http://localhost:9080/swagger-ui.html>

**Lệnh quản lý Docker hữu ích:**
- Xem log: `docker compose --project-name veggiepal-prm logs -f --tail 50`
- Dừng hệ thống: `docker compose --project-name veggiepal-prm down` *(Lưu ý: Không dùng `-v` để tránh mất dữ liệu MySQL)*.

---

### Cách 2: Khởi chạy Backend thủ công (Local Development)

Dành cho nhà phát triển muốn debug từng service bằng IDE (IntelliJ IDEA / Eclipse / VS Code):

**Bước 1: Bật hạ tầng MySQL & Ngrok:**
```powershell
Set-Location backend
docker compose -f docker-compose.infra.yml --project-name veggiepal-prm up -d
```

**Bước 2: Nạp cơ sở dữ liệu:**
Chạy script `init_database.sql` như hướng dẫn ở Mục 5.

**Bước 3: Khởi chạy từng service bằng Maven (theo thứ tự khuyến nghị):**
Mỗi service là một dự án Maven độc lập. Mở từng terminal riêng biệt:

1. **Identity Service:**
   ```powershell
   cd backend/identity-service
   mvn spring-boot:run
   ```
2. **Nutrition Service:**
   ```powershell
   cd backend/nutrition-service
   mvn spring-boot:run
   ```
3. **Recipe Service:**
   ```powershell
   cd backend/recipe-service
   mvn spring-boot:run
   ```
4. **Location Service:**
   ```powershell
   cd backend/location-service
   mvn spring-boot:run
   ```
5. **Blog Service:**
   ```powershell
   cd backend/blog-service
   mvn spring-boot:run
   ```
6. **Payment Service:**
   ```powershell
   cd backend/payment-service
   mvn spring-boot:run
   ```
7. **AI Service:**
   ```powershell
   cd backend/ai-service
   mvn spring-boot:run
   ```
8. **API Gateway (Bắt buộc chạy sau cùng):**
   ```powershell
   cd backend/api-gateway
   mvn spring-boot:run
   ```

---

### Cách 3: Khởi chạy Web Client (React 19 + Vite)

**Bước 1:** Di chuyển vào thư mục `frontend`:
```powershell
Set-Location frontend
```

**Bước 2:** Cài đặt các gói phụ thuộc (Dependencies):
```powershell
npm install
```

**Bước 3:** Đảm bảo file `.env` đã có biến trỏ đến Gateway:
```dotenv
VITE_VEGGIEPAL_API_BASE_URL=http://localhost:9080/api
```

**Bước 4:** Khởi chạy máy chủ phát triển (Vite Dev Server):
```powershell
npm run dev
```

Ứng dụng web sẽ chạy tại: **<http://localhost:5173>**

**Các lệnh kiểm tra Web:**
- `npm run build`: Đóng gói ứng dụng cho production (thư mục `dist/`).
- `npm run lint`: Kiểm tra chất lượng mã nguồn bằng ESLint.
- `npm test`: Chạy kiểm thử tự động.

---

### Cách 4: Khởi chạy Mobile App (Flutter)

**Bước 1:** Di chuyển vào thư mục `mobile`:
```powershell
Set-Location mobile
```

**Bước 2:** Tải các gói thư viện Flutter:
```powershell
flutter pub get
```

**Bước 3:** Cấu hình file `mobile/.env`:
- Đối với **Android Emulator**: Đặt `API_BASE_URL=http://10.0.2.2:9080/api`
- Đối với **iOS Simulator**: Đặt `API_BASE_URL=http://localhost:9080/api`
- Đối với **Thiết bị thật (Physical Phone)**: Kết nối điện thoại và máy tính vào cùng một mạng Wi-Fi, đặt `API_BASE_URL=http://<IP_LAN_MAY_TINH>:9080/api` (Ví dụ: `http://192.168.1.15:9080/api`).

**Bước 4:** Kiểm tra thiết bị kết nối và khởi chạy:
```powershell
# Liệt kê thiết bị
flutter devices

# Chạy ứng dụng trên thiết bị mục tiêu
flutter run
```

---

### Cách 5: Thiết lập Local AI Runner (Tùy chọn)

Mặc định, `ai-service` có chế độ mock thông minh giúp toàn bộ chức năng (lập thực đơn, chatbot, kiểm duyệt) hoạt động ngay lập tức mà không cần GPU cấu hình cao.

Nếu bạn muốn chạy mô hình AI tự host cục bộ:
1. Dự án hỗ trợ mô hình **Qwen2.5-1.5B-Instruct** thông qua **llama.cpp** server.
2. Tham khảo hướng dẫn cấu hình trong thư mục `backend/ai-inference/compose.local-ai.yml`.
3. Bật profile AI local trong `backend/.env`:
   ```dotenv
   AI_SERVICE_PROFILES=local
   AI_LOCAL_BASE_URL=http://llama:8080/v1
   AI_LOCAL_MODEL=qwen2.5-1.5b-instruct
   ```

---

## 8. Tài khoản kiểm thử & Phân quyền

Cơ sở dữ liệu sau khi nạp file `init_database.sql` đã có sẵn 3 tài khoản mẫu được kích hoạt sẵn (`status = ACTIVE`, `email_verified = true`):

| Email | Mật khẩu | Quyền hạn (Role) | Chức năng kiểm thử nổi bật |
|---|---|:---:|---|
| **`admin@veggiepal.com`** | `password` | **ADMIN** | Truy cập trang Quản trị, duyệt hàng đợi kiểm duyệt AI, xem nhật ký & chi phí token AI, quản lý danh sách người dùng, thống kê doanh thu PayOS |
| **`user@veggiepal.com`** | `password` | **USER** | Lên thực đơn 7 ngày, chat với AI, ghi nhật ký ăn uống & thể chất, đăng bài blog, chia sẻ video, thanh toán gói PLUS/PRO |
| **`user2@veggiepal.com`** | `password` | **USER** | Tác giả nội dung thứ hai dùng để test tính năng follow tác giả, bình luận chéo và upvote/downvote |

### Bảng phân quyền chi tiết:

| Tính năng | Khách (GUEST) | Thành viên (USER) | Quản trị viên (ADMIN) |
|---|:---:|:---:|:---:|
| Xem công thức, quán chay, blog công khai | Có | Có | Có |
| Chatbot AI thử nghiệm | Có (Giới hạn 3 lượt/ngày) | Có (Theo gói FREE/PLUS/PRO) | Có (Không giới hạn) |
| Lập thực đơn AI 7 ngày | Không | Có (Theo gói đăng ký) | Có |
| Lưu nhật ký dinh dưỡng & theo dõi sức khỏe | Không | Có | Có |
| Đăng bài viết, đăng video, bình luận | Không | Có (Tự động kiểm duyệt AI) | Có |
| Nâng cấp gói thành viên qua VietQR | Không | Có | Có |
| Quản lý tài khoản, phân quyền, khóa người dùng | Không | Không | **Có** |
| Duyệt bài kiểm duyệt bị giữ lại (Moderation Queue)| Không | Không | **Có** |
| Giám sát hệ thống AI (AI Usage & Token Latency)  | Không | Không | **Có** |

---

## 9. Hướng dẫn sử dụng các luồng nghiệp vụ chính

### 9.1. Đăng ký & Đăng nhập
- Người dùng có thể đăng ký tài khoản mới bằng Email. Hệ thống sẽ gửi mã OTP 6 số qua email để xác thực.
- Hỗ trợ đăng nhập Google một chạm trên cả Web và Mobile.
- Nếu quên mật khẩu, người dùng bấm "Quên mật khẩu", nhập mã OTP 6 số gửi về email và tạo mật khẩu mới.

### 9.2. Khai báo Sức khỏe & Dị ứng
- Vào mục **Hồ sơ cá nhân (Profile) > Sức khỏe & Dị ứng**.
- Nhập chiều cao, cân nặng: Hệ thống tự động tính toán chỉ số BMI và phân loại thể trạng.
- Chọn các chất gây dị ứng (ví dụ: Đậu phộng, Gluten, Đậu nành...). Khi lập thực đơn AI, hệ thống sẽ **tự động loại bỏ hoàn toàn** các món chứa thành phần này.

### 9.3. Lập Thực đơn Dinh dưỡng 7 ngày bằng AI
- Vào phân hệ **Thực đơn AI (Meal Planner)**.
- Chọn mục tiêu thể trạng (Giữ cân, Giảm cân, Tăng cơ) và mức độ vận động.
- Hệ thống AI sẽ tính toán lượng calo mục tiêu (BMR & TDEE) và sinh ra bảng thực đơn gồm 21 bữa ăn (Sáng, Trưa, Tối trong 7 ngày) từ kho 115 công thức thực tế.
- Người dùng có thể:
  - Đổi món cho từng bữa nếu muốn thay đổi khẩu vị.
  - Lưu thực đơn vào danh sách Yêu thích.
  - Xem và khôi phục các phiên bản thực đơn đã lưu trong lịch sử.

### 9.4. Nhật ký Dinh dưỡng & Thể chất
- **Nhật ký ăn uống (Food Log):** Ghi lại các món đã ăn trong ngày theo bữa. Hệ thống tính tổng Calo, Đạm (Protein), Đường bột (Carbs), Chất béo (Fat), Chất xơ (Fiber) và đối chiếu với mức calo mục tiêu.
- **Nhật ký thể chất (Wellness Log):** Theo dõi lượng nước uống (ml) so với mục tiêu 2.400 ml/ngày, số bước chân, thời gian vận động và lượng calo tiêu hao.

### 9.5. Chia sẻ Cộng đồng & Bóc tách Video AI
- Người dùng có thể đăng bài viết Blog chia sẻ kinh nghiệm hoặc đăng Video hướng dẫn nấu ăn từ YouTube hoặc tệp tải lên.
- **Bóc tách tự động AI:** Với các video nấu ăn, AI tự động phân tích và trích xuất danh sách nguyên liệu, định lượng và giá trị dinh dưỡng ước tính.
- **Hệ thống Kiểm duyệt AI (AI Moderation):** Mọi bài viết hoặc bình luận khi đăng sẽ được AI phân tích nội dung. Nếu phát hiện vi phạm tiêu chuẩn hoặc chứa ngôn từ không phù hợp, bài viết sẽ được đưa vào hàng đợi kiểm duyệt để Admin xem xét trước khi hiển thị công khai.

### 9.6. Tìm kiếm Quán ăn chay & Bản đồ
- Vào phân hệ **Bản đồ Quán chay (Restaurants Map)**.
- Cho phép trình duyệt/ứng dụng truy cập vị trí hiện tại.
- Hệ thống sẽ hiển thị danh sách các quán ăn chay gần nhất theo bán kính (tính toán khoảng cách bằng công thức cầu `ST_Distance_Sphere`).
- Hỗ trợ tìm kiếm theo tên quán, địa chỉ và lọc các quán "Thuần chay" (Vegan Only).

### 9.7. Nâng cấp Gói hội viên PayOS VietQR
- Vào mục **Gói hội viên (Subscription)**.
- Chọn gói nâng cấp:
  - **Gói FREE:** Miễn phí, 5 lượt chat AI/ngày, 2 thực đơn AI/tháng.
  - **Gói PLUS (29.000 VNĐ / 30 ngày):** 20 lượt chat AI/ngày, 8 thực đơn AI/tháng.
  - **Gói PRO (59.000 VNĐ / 30 ngày):** 50 lượt chat AI/ngày, 20 thực đơn AI/tháng.
- Hệ thống gọi PayOS tạo đơn hàng và hiển thị mã VietQR động cùng thông tin chuyển khoản chính xác.
- Khi người dùng quét mã thanh toán bằng ứng dụng ngân hàng, PayOS gửi Webhook tức thời qua Ngrok vào Payment Service để kích hoạt gói thành công chỉ sau vài giây.

---

## 10. Tài liệu API & Swagger UI

API Gateway cung cấp giao diện tài liệu OpenAPI/Swagger tập trung, cho phép xem và gọi thử API của toàn bộ 7 microservices tại một địa chỉ duy nhất:

👉 **URL Swagger UI:** **<http://localhost:9080/swagger-ui.html>**  
👉 **Tài liệu đặc tả chi tiết kèm ví dụ Request/Response:** Xem tại file [`API_DOCUMENTATION.md`](API_DOCUMENTATION.md) ở thư mục gốc.

Tại góc trên bên phải của Swagger UI, bạn có thể chọn danh mục (Spec) của từng service:
- `identity-service`: `/v3/api-docs/identity`
- `nutrition-service`: `/v3/api-docs/nutrition`
- `blog-service`: `/v3/api-docs/blog`
- `recipe-service`: `/v3/api-docs/recipe`
- `location-service`: `/v3/api-docs/location`
- `ai-service`: `/v3/api-docs/ai`
- `payment-service`: `/v3/api-docs/payment`

### Quy ước Chuẩn API:
1. **Định dạng dữ liệu trả về (Envelope Format):**
   Mọi response đều trả về cấu trúc JSON thống nhất:
   ```json
   {
     "code": 1000,
     "message": "Thao tác thành công",
     "result": { ... }
   }
   ```
2. **Xác thực (Authentication):**
   Các API yêu cầu đăng nhập cần truyền header:
   ```http
   Authorization: Bearer <access_token>
   ```

---

## 11. Xử lý sự cố thường gặp (Troubleshooting)

### 1. Trùng cổng (Port Conflict) 9080 hoặc 4307 khi chạy Docker
- **Hiện tượng:** Docker báo lỗi `bind: address already in use`.
- **Cách xử lý:** Mở file `backend/.env`, đổi giá trị `PRM_GATEWAY_HOST_PORT` (ví dụ thành `9081`) hoặc `PRM_MYSQL_HOST_PORT` (ví dụ thành `4308`), sau đó chạy lại `docker compose up -d`.

### 2. Android Emulator không kết nối được Backend
- **Hiện tượng:** App Flutter báo `Connection refused` hoặc timeout khi đăng nhập.
- **Nguyên nhân:** Trên Android Emulator, địa chỉ `localhost` trỏ vào chính máy ảo, không phải máy tính chạy backend.
- **Cách xử lý:** Đảm bảo trong `mobile/.env` đặt `API_BASE_URL=http://10.0.2.2:9080/api`.

### 3. Webhook PayOS không kích hoạt gói sau khi thanh toán
- **Hiện tượng:** Quét mã VietQR thành công nhưng tài khoản vẫn ở gói cũ.
- **Nguyên nhân:** Ngrok chưa được cấp AuthToken hoặc URL webhook chưa được đăng ký trong cổng PayOS.
- **Cách xử lý:**
  1. Mở trang Ngrok Inspector: <http://localhost:5041> để lấy domain public ngrok hiện tại (ví dụ: `https://xxxx.ngrok-free.app`).
  2. Truy cập trang quản trị PayOS, cập nhật Webhook URL thành:  
     `https://xxxx.ngrok-free.app/api/payments/webhook/payos`
  3. Kiểm tra tab Request trong Ngrok Inspector để xem log webhook trả về mã `200 OK`.

### 4. Lỗi CORS khi gọi API từ Web
- **Hiện tượng:** Trình duyệt báo `Cross-Origin Request Blocked`.
- **Cách xử lý:** Đảm bảo Web client đang gọi qua API Gateway tại port `9080` (được cấu hình CORS cho phép `http://localhost:5173`), không gọi trực tiếp vào port nội bộ của các microservice.

---

## 12. Quy trình CI/CD Tự động hóa

Dự án thiết lập pipeline CI/CD hoàn chỉnh trên **GitHub Actions** tại file [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) bao phủ cả 3 nền tảng: **Backend**, **Frontend**, và **Mobile**.

### 12.1. Cơ chế kích hoạt (Triggers)
- Tự động chạy khi có sự kiện `push` hoặc mở/cập nhật `pull_request` vào 2 nhánh chính: `dev` và `main`.
- Lắng nghe thay đổi trên các đường dẫn: `backend/**`, `frontend/**`, `mobile/**`, và `.github/workflows/ci-cd.yml`.

### 12.2. Các giai đoạn (Pipeline Jobs)

```text
                                  ┌────────────────────────┐
                                  │   Code Push / PR       │
                                  └───────────┬────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    │                         │                         │
            ┌───────▼───────┐         ┌───────▼───────┐         ┌───────▼───────┐
            │  BACKEND CI   │         │  FRONTEND CI  │         │   MOBILE CI   │
            │ (Maven 8 svcs)│         │ (React 19)    │         │ (Flutter)     │
            └───────┬───────┘         └───────┬───────┘         └───────┬───────┘
                    │                         │                         │
                    ▼                         ▼                         ▼
            ┌───────────────┐         ┌───────────────┐         ┌───────────────┐
            │ Docker Build  │         │  Artifact:    │         │  Artifact:    │
            │ (8 images)    │         │ frontend-dist │         │  mobile-apk   │
            └───────┬───────┘         └───────┬───────┘         └───────┬───────┘
                    │                         │                         │
                    ▼                         │                         │
            ┌───────────────┐                 │                         │
            │ Compose Check │                 │                         │
            └───────┬───────┘                 │                         │
                    │                         │                         │
                    └─────────────────────────┼─────────────────────────┘
                                              │ (Chỉ chạy khi push dev/main & tất cả CI passed)
                                      ┌───────▼───────┐
                                      │ CD DEPLOYMENT │
                                      │(Win Self-host)│
                                      └───────────────┘
```

| Nhóm | Tên Job | Môi trường | Mô tả chi tiết |
|---|---|---|---|
| **Backend** | `maven` | `ubuntu-latest` (Matrix 8 services) | Chạy kiểm thử tự động (Unit & Integration tests) và đóng gói JAR cho từng microservice với MySQL 8.4 service container. |
| **Backend** | `docker` | `ubuntu-latest` (Matrix 8 services) | Kiểm tra quá trình đóng gói Dockerfile cho toàn bộ 8 services. |
| **Backend** | `compose-check` | `ubuntu-latest` | Xác thực cấu hình `docker-compose.yml` (environment, ports, networks). |
| **Frontend** | `frontend` | `ubuntu-latest` | Cài đặt Node.js 22, kiểm tra chuẩn mã nguồn bằng **ESLint**, chạy unit test, đóng gói bản production bằng **Vite** và xuất artifact `veggiepal-frontend-dist`. |
| **Mobile** | `mobile` | `ubuntu-latest` | Cài đặt JDK 17 & Flutter stable, kiểm tra mã nguồn bằng `flutter analyze`, chạy bộ test UI/Widget `flutter test`, build Android APK `flutter build apk --debug` và xuất artifact `veggiepal-mobile-apk`. |
| **Deploy** | `deploy` | `self-hosted` (Windows X64) | Tự động cập nhật và khởi chạy toàn bộ hệ thống bằng `docker compose up -d --build` khi push lên `dev` hoặc `main`, xác minh health check của từng container. |

### 12.3. Tải về Bản dựng (Build Artifacts)
Sau mỗi lần pipeline chạy thành công, nhóm phát triển và người kiểm thử có thể tải trực tiếp các tệp đóng gói từ tab **Actions** trên GitHub:
- **`veggiepal-frontend-dist`**: Bản dựng web tĩnh sẵn sàng đưa lên máy chủ Web (Nginx/Hosting).
- **`veggiepal-mobile-apk`**: Tệp cài đặt Android APK sẵn sàng cài đặt trực tiếp lên điện thoại thật để thử nghiệm.

---

## Liên hệ & Hỗ trợ

- **Dự án:** VeggiePal Microservices Ecosystem
- **Đồ án Capstone:** Môn PRM393 - FPT University
- **Báo cáo Kỹ thuật & Nghiên cứu:** Tham khảo chi tiết tại `init_database.sql` và tài liệu kiến trúc hệ thống.
