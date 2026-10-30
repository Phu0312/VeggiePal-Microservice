# VeggiePal

Hệ sinh thái số hỗ trợ lối sống ăn chay: theo dõi sức khỏe và dị ứng, lên thực đơn 7 ngày bằng AI, trò chuyện với trợ lý AI, cộng đồng blog/video, tìm quán chay gần bạn và đăng ký gói thành viên qua PayOS VietQR.

Đồ án môn PRM393 (FPT University). Báo cáo đầy đủ: [docs/PRM_CAPSTONE.md](docs/PRM_CAPSTONE.md).

## Mục lục

- [Cấu trúc repository](#cấu-trúc-repository)
- [Kiến trúc](#kiến-trúc)
- [Chức năng chính](#chức-năng-chính)
- [Công nghệ](#công-nghệ)
- [Yêu cầu môi trường](#yêu-cầu-môi-trường)
- [Chạy nhanh](#chạy-nhanh)
- [Port và địa chỉ](#port-và-địa-chỉ)
- [Cấu hình `.env`](#cấu-hình-env)
- [Kiểm thử và kiểm tra code](#kiểm-thử-và-kiểm-tra-code)
- [Cấu trúc mã nguồn web và mobile](#cấu-trúc-mã-nguồn-web-và-mobile)
- [CI/CD](#cicd)
- [Self-hosted runner trên Windows](#self-hosted-runner-trên-windows)
- [Tài liệu liên quan](#tài-liệu-liên-quan)

## Cấu trúc repository

Monorepo gồm ba ứng dụng:

| Thư mục | Nội dung | Công nghệ |
|---|---|---|
| [backend/](backend) | 7 service nghiệp vụ + 1 API gateway, mỗi service là một Maven project độc lập (không có parent POM) | Java 21, Spring Boot 4.1.1, MySQL 8.4 |
| [frontend/](frontend) | Ứng dụng web | React 19, Vite 8, Tailwind CSS v4 |
| [mobile/](mobile) | Ứng dụng di động | Flutter (Dart `^3.13.2`), Dio, Provider |
| [docs/](docs) | Báo cáo capstone và tài liệu yêu cầu | Markdown |
| [.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml) | Pipeline CI/CD | GitHub Actions |

## Kiến trúc

Client (web, mobile) chỉ gọi **API Gateway**; gateway định tuyến tới từng service. Mỗi service có schema MySQL riêng (database-per-service), không có khóa ngoại giữa các schema. Các service gọi nhau qua REST đồng bộ khi cần, không dùng message broker.

```text
Web (React)  ─┐
              ├─►  api-gateway :8080 (host 9080) ─┬─► identity-service  :8081
Mobile (Flutter) ─┘                               ├─► nutrition-service :8082
                                                  ├─► blog-service      :8083
PayOS ──► Ngrok ──► api-gateway                   ├─► recipe-service    :8084
                                                  ├─► location-service  :8085
                                                  ├─► ai-service        :8086
                                                  └─► payment-service   :8087
                                                          │
                                                  MySQL 8.4 (mỗi service một schema)
```

| Service | Port trong container | Route qua gateway | Trách nhiệm |
|---|---:|---|---|
| `api-gateway` | 8080 | — | Routing, CORS, Swagger UI tổng hợp |
| `identity-service` | 8081 | `/api/auth/**`, `/api/users/**` | Tài khoản, đăng nhập (JWT, Google), hồ sơ, quản trị người dùng |
| `nutrition-service` | 8082 | `/api/nutrition/**` | Chiều cao/cân nặng/BMI, danh mục và dị ứng của người dùng |
| `blog-service` | 8083 | `/api/blogs/**`, `/api/categories/**`, `/api/comments/**`, `/api/videos/**` | Blog, video, danh mục, bình luận, vote |
| `recipe-service` | 8084 | `/api/recipes/**`, `/api/ingredients/**` | Công thức, nguyên liệu |
| `location-service` | 8085 | `/api/restaurants/**` | Quán chay và tìm quán gần vị trí |
| `ai-service` | 8086 | `/api/ai/**`, `/ai/**` | Chatbot, thực đơn 7 ngày, bóc tách công thức từ video, kiểm duyệt, hạn mức, giám sát |
| `payment-service` | 8087 | `/api/payments/**`, `/api/subscriptions/**`, `/api/admin/payments/**` | Gói thành viên, đơn PayOS, webhook, hạn mức theo gói, thống kê cho admin |

Hạ tầng đi kèm: MySQL 8.4, Ngrok (đưa webhook PayOS vào gateway), Cloudinary (ảnh/video) và Groq (LLM, speech-to-text). Sơ đồ chi tiết ở mục IV của báo cáo.

Swagger UI tổng hợp của gateway gom tài liệu API của các service (xem [Port và địa chỉ](#port-và-địa-chỉ)). Mọi response dùng envelope `{ code, message, result }`; các endpoint cần đăng nhập nhận `Authorization: Bearer <JWT>`.

## Chức năng chính

| Nhóm | Mô tả | Web | Mobile |
|---|---|:---:|:---:|
| Tài khoản | Đăng ký, đăng nhập, đăng nhập Google, hồ sơ, ảnh đại diện, đổi mật khẩu | ✓ | ✓ |
| Quên mật khẩu, xác minh email, giữ phiên | Đặt lại mật khẩu bằng mã OTP 6 số, xác minh email, tự làm mới phiên bằng refresh token | ✓ | ✓ |
| Sức khỏe | Ghi chiều cao/cân nặng, lịch sử BMI, khai báo dị ứng | ✓ | ✓ |
| Nhật ký dinh dưỡng | Ghi món ăn theo bữa, nước uống, vận động; calo và macro so với mục tiêu theo ngày | ✓ | ✓ |
| Thực đơn AI | Thực đơn 7 ngày × 3 bữa từ công thức thật, loại món chứa chất dị ứng đã khai báo, mục tiêu calo/macro do BE tính, đổi món, thực đơn yêu thích, lịch sử phiên bản | ✓ | ✓ |
| Chatbot | Hỏi đáp dinh dưỡng chay, nhiều đoạn chat; khách được dùng thử có giới hạn theo ngày | ✓ | ✓ |
| Video | Đăng video (.mp4 hoặc liên kết YouTube), bóc tách nguyên liệu và các bước nấu bằng AI | ✓ | ✓ |
| Blog | Blog, bình luận nhiều cấp, vote, danh mục, kiểm duyệt tự động | ✓ | ✓ |
| Công thức, nguyên liệu | Tra cứu, tạo và đăng công thức, danh mục nguyên liệu, thích công thức, tải ảnh lên; mobile có thêm sắp xếp phổ biến | ✓ | ✓ |
| Bản đồ | Tìm quán chay gần vị trí của bạn và tìm theo từ khoá trên toàn bộ quán | ✓ (Mapbox) | ✓ (flutter_map) |
| Gói thành viên | FREE / PLUS (29.000 VND) / PRO (59.000 VND), thanh toán PayOS VietQR, hạn mức chat, thực đơn và video theo gói | ✓ | ✓ |
| Quản trị (ADMIN) | Hàng đợi kiểm duyệt, giám sát AI, thống kê thanh toán | ✓ | ✓ |
| Cộng đồng | Bảng xếp hạng tác giả, chủ đề nổi bật, theo dõi tác giả, thử thách 7 ngày | ✓ | ✓ |
| Yêu thích, huy hiệu | Lưu công thức / bài viết / video, huy hiệu xanh, dinh dưỡng của video; mobile có thêm vote video | ✓ | ✓ |
| Hạn mức AI | Xem lượt chat, thực đơn, bóc tách video đã dùng và còn lại; khôi phục phiên bản thực đơn | ✓ | ✓ |
| Quản lý tài khoản (ADMIN) | Tìm và lọc tài khoản, khóa / mở khóa, cấp hoặc gỡ quyền quản trị | ✓ | ✓ |

## Công nghệ

| Phần | Công nghệ |
|---|---|
| Backend | Java 21, Spring Boot 4.1.1, Spring Cloud Gateway Server WebMVC 2025.1.3, Spring Data JPA, Spring Security OAuth2 Resource Server (JWT HS256), MySQL 8.4, MapStruct, Lombok, springdoc OpenAPI, JUnit 5 + Mockito |
| Web | React 19, Vite 8, Tailwind CSS v4, shadcn/ui (`@base-ui/react`), React Router v7, TanStack Query v5, Zustand v5, React Hook Form + Zod, Axios, Mapbox GL, `qrcode.react`, ESLint 10 |
| Mobile | Flutter (Dart `^3.13.2`), Dio, Provider, `flutter_secure_storage`, `google_sign_in`, `flutter_map` + `geolocator`, `video_player` + `youtube_player_iframe`, `qr_flutter`, `image_picker` |
| Hạ tầng | Docker Compose, GitHub Actions, Ngrok, Cloudinary, Groq, PayOS |

## Yêu cầu môi trường

- Docker Desktop (Docker Compose v2+).
- Git.
- JDK 21: chỉ cần khi chạy service ngoài Docker hoặc chạy test cục bộ.
- Node.js `^20.19.0` hoặc `>=22.12.0`: cho web.
- Flutter SDK tương thích Dart `^3.13.2`: cho mobile.
- Kết nối internet và `GROQ_API_KEY` cho các tính năng AI.

## Chạy nhanh

### 1. Backend (Docker Compose)

```powershell
Copy-Item backend/.env.example backend/.env   # rồi điền giá trị thật
Set-Location backend
docker compose --project-name veggiepal-prm up -d --build --wait --wait-timeout 300
docker compose --project-name veggiepal-prm ps
```

Kiểm tra: mở <http://localhost:9080/swagger-ui.html>.

Dừng stack: `docker compose --project-name veggiepal-prm down`. Không dùng `down -v` hoặc lệnh dọn toàn bộ Docker vì sẽ xóa dữ liệu MySQL hoặc ảnh hưởng project khác.

Xem log: `docker compose --project-name veggiepal-prm logs --tail 100`.

### 2. Web

```powershell
Set-Location frontend
Copy-Item .env.example .env   # đặt VITE_VEGGIEPAL_API_BASE_URL=http://localhost:9080/api
npm install
npm run dev                   # http://localhost:5173
```

| Lệnh | Mô tả |
|---|---|
| `npm run dev` | Chạy môi trường phát triển (Vite) |
| `npm run build` | Build production vào `frontend/dist/` |
| `npm run preview` | Chạy thử bản build |
| `npm run lint` | Kiểm tra code với ESLint |
| `npm test` | Chạy các file `*.test.js` bằng `node:test` |

### 3. Mobile

```powershell
Set-Location mobile
Copy-Item .env.example .env
flutter pub get
flutter run
```

Giá trị `API_BASE_URL` trong `mobile/.env` phụ thuộc thiết bị chạy app:

| Thiết bị | `API_BASE_URL` |
|---|---|
| Android emulator | `http://10.0.2.2:9080/api` (`localhost` trong emulator là chính emulator, không phải máy host) |
| Web / Windows / iOS simulator | `http://localhost:9080/api` |
| Điện thoại thật | `http://<IP-LAN-của-máy-chạy-backend>:9080/api` |

Để trống `API_BASE_URL` thì app tự chọn theo nền tảng. `.env` được đóng gói vào app lúc build nên sau khi đổi phải chạy lại hẳn (không dùng hot reload).

## Port và địa chỉ

| Thành phần | Địa chỉ trên máy host |
|---|---|
| API Gateway | <http://localhost:9080> (container 8080) |
| Swagger UI tổng hợp | <http://localhost:9080/swagger-ui.html> |
| MySQL | `127.0.0.1:4307` |
| Ngrok inspector | <http://localhost:5041> |
| Web (Vite dev) | <http://localhost:5173> |

Chỉ ba port đầu (9080, 4307, 5041) được publish ra host; các service còn lại chỉ truy cập được trong mạng Docker. Có thể đổi bằng `PRM_GATEWAY_HOST_PORT`, `PRM_MYSQL_HOST_PORT`, `PRM_NGROK_INSPECTOR_HOST_PORT` trong `backend/.env`.

## Cấu hình `.env`

Không commit `.env` hoặc credential thật; chỉ commit các file `.env.example`.

| File | Dùng cho |
|---|---|
| `backend/.env` (mẫu: [backend/.env.example](backend/.env.example)) | Toàn bộ backend và Docker Compose |
| `frontend/.env` (mẫu: [frontend/.env.example](frontend/.env.example)) | Web |
| `mobile/.env` (mẫu: [mobile/.env.example](mobile/.env.example)) | Mobile. Không để secret thật vì file được đóng gói vào app |

### Backend

Biến bắt buộc để stack khởi động:

```dotenv
DB_PASSWORD=...
JWT_SECRET=...
INTERNAL_SERVICE_TOKEN=...
NGROK_AUTHTOKEN=...
```

Các biến còn lại bật tính năng tương ứng: `GROQ_API_KEY` (AI), `CLOUDINARY_*` (ảnh, video), `GOOGLE_CLIENT_ID` (đăng nhập Google), `PAYOS_*` (thanh toán). Xem danh sách đầy đủ và giá trị mặc định trong `backend/.env.example`.

Webhook PayOS đăng ký bằng URL public `https://<ngrok-domain>/api/payments/webhook/payos`; domain Ngrok hiện tại xem tại Ngrok inspector. Return/cancel URL của PayOS trỏ về frontend và cấu hình qua `PAYOS_RETURN_URL`, `PAYOS_CANCEL_URL`.

### Web

| Biến | Mô tả |
|---|---|
| `VITE_VEGGIEPAL_API_BASE_URL` | Base URL của gateway, đã gồm `/api` (ví dụ `http://localhost:9080/api`) |
| `VITE_GOOGLE_CLIENT_ID` | Google OAuth Web client ID; phải trùng `GOOGLE_CLIENT_ID` của identity-service. Origin `http://localhost:5173` phải nằm trong Authorized JavaScript origins |
| `VITE_MAPBOX_TOKEN`, `VITE_MAPBOX_STYLE` | Token và style cho bản đồ. Thiếu token thì trang bản đồ hiện thông báo thay vì bản đồ |

### Mobile

| Biến | Mô tả |
|---|---|
| `API_BASE_URL` | URL gateway kèm `/api` (xem bảng theo thiết bị ở trên) |
| `GOOGLE_CLIENT_ID` | OAuth Web client ID, trùng `GOOGLE_CLIENT_ID` của identity-service. Để trống thì nút Google báo chưa cấu hình. Android cần thêm một OAuth client loại Android (package `com.veggiepal.mobile` + SHA-1 của khóa ký) |
| `GOOGLE_IOS_CLIENT_ID` | OAuth client loại iOS, chỉ cần khi build iOS |

## Kiểm thử và kiểm tra code

| Phần | Lệnh | Ghi chú |
|---|---|---|
| Backend | `mvn test` trong thư mục từng service (hoặc `./mvnw test`) | Mỗi service là một Maven project riêng. Một số test `@SpringBootTest` cần MySQL; lệnh loại trừ và quy ước nằm trong [backend/CLAUDE.md](backend/CLAUDE.md) |
| Web | `npm run lint`, `npm test` | `npm test` chạy `node --test "src/**/*.test.js"` |
| Mobile | `flutter analyze`, `flutter test` | Test nằm ở [mobile/test/](mobile/test) |

## Cấu trúc mã nguồn web và mobile

### Web (`frontend/src`)

```text
app/            App, provider (Query + Router), routes
components/ui/  Component shadcn/ui
features/       admin, auth, blog, chatbot, community, diary, home, ingredient,
                meal-planner, my-content, payment, profile, recipe, restaurant-map, video
lib/            queryClient, schema zod, cn
shared/         apiClient (axios), component dùng chung, store, hooks
styles/         globals.css (Tailwind + design token)
```

Alias import `@/` trỏ tới `src/`. Quy ước công nghệ và UI: [frontend/docs/TECH_STACK.md](frontend/docs/TECH_STACK.md).

### Mobile (`mobile/lib`)

```text
core/        constants (endpoints, màu, chuỗi), network (Dio), storage (phiên đăng nhập),
             theme, utils, widget dùng chung
features/    admin, ai_nutrition, auth, blog, home, ingredient, menu_planner,
             notifications, payment, places, profile, recipe, video
navigation/  Thanh điều hướng dưới và màn hình chính
```

Mỗi feature chia `data/` (repository, model) và `presentation/` (màn hình, controller).

## CI/CD

Workflow [.github/workflows/ci-cd.yml](.github/workflows/ci-cd.yml) chạy khi push hoặc mở/cập nhật pull request vào `dev` hoặc `main`.

| Job | Chạy ở đâu | Nội dung |
|---|---|---|
| `maven` | GitHub-hosted Ubuntu, MySQL 8.4 làm service container | Với từng trong 8 module backend: chạy test và package |
| `docker` | GitHub-hosted Ubuntu | Build Dockerfile của từng module |
| `compose-check` | GitHub-hosted Ubuntu | Kiểm tra cấu hình Docker Compose |
| `deploy` | Self-hosted Windows runner | Chỉ chạy khi **push** vào `dev` hoặc `main` sau khi CI thành công: `docker compose --project-name veggiepal-prm up -d --build --wait --wait-timeout 300`, rồi kiểm tra trạng thái và healthcheck của các container thuộc project |

Pull request chỉ chạy CI, không deploy. Workflow chỉ build và deploy backend; web và mobile chưa có job CI.

### Cấp `.env` cho job deploy

Chọn một trong hai cách:

1. **Secret (khuyến nghị):** tạo repository secret `BACKEND_ENV_FILE` tại **Settings > Secrets and variables > Actions**, giá trị là toàn bộ nội dung `backend/.env`. Workflow ghi secret thành `.env` trên runner mà không in ra log. Nếu cần tách cấu hình `dev` và `main`, dùng GitHub Environment secrets và gắn environment vào job `deploy`.
2. **File có sẵn trên runner:** sau lần checkout đầu tiên, tạo `backend/.env` từ `backend/.env.example` trên máy runner. Workflow đặt `clean: false` nên file này được giữ giữa các lần checkout.

## Self-hosted runner trên Windows

1. Cài Git for Windows và Docker Desktop; bật Linux containers và chờ Docker Desktop ở trạng thái running.
2. Vào GitHub repository: **Settings > Actions > Runners > New self-hosted runner > Windows > x64**.
3. Trong PowerShell, làm đúng các lệnh tải xuống và cấu hình GitHub hiển thị. Không cài runner bên trong thư mục repository.
4. Giữ các label mặc định `self-hosted`, `Windows`, `X64`.
5. Chạy thử bằng `run.cmd`. Để tự khởi động cùng Windows, chạy `config.cmd` bằng quyền Administrator và chọn chạy dưới dạng Windows service.
6. Tài khoản chạy runner phải dùng được Docker Desktop; kiểm tra bằng `docker version` và `docker compose version`.

Runner cần online liên tục để nhận job deploy. Không dùng chung runner này cho repository không tin cậy.

## Tài liệu liên quan

- [docs/PRM_CAPSTONE.md](docs/PRM_CAPSTONE.md): báo cáo capstone (yêu cầu, thiết kế, kiểm thử, hướng dẫn).
- [backend/README.md](backend/README.md), [backend/CLAUDE.md](backend/CLAUDE.md): tài liệu và quy ước backend.
- [frontend/CLAUDE.md](frontend/CLAUDE.md), [frontend/docs/TECH_STACK.md](frontend/docs/TECH_STACK.md): quy ước web.
- [AGENTS.md](AGENTS.md): quy tắc cho AI coding agent, gồm yêu cầu giữ báo cáo đồng bộ với code.
