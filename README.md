# VeggiePal Microservice

Repository gồm backend Spring Boot microservices, frontend và mobile. Backend được triển khai local bằng file Compose có sẵn tại `backend/docker-compose.yml`.

## CI/CD GitHub Actions

Workflow `.github/workflows/ci-cd.yml` chạy khi push hoặc mở/cập nhật pull request vào `dev`, `main`:

- CI trên GitHub-hosted Ubuntu: restore Maven dependencies, chạy toàn bộ test, package 8 Spring Boot service, build từng Dockerfile và kiểm tra cấu hình Docker Compose.
- CD trên Windows self-hosted runner: chỉ chạy sau CI thành công đối với sự kiện push vào `dev` hoặc `main`; pull request không deploy.
- CD chạy `docker compose up -d --build --wait --wait-timeout 300`, sau đó kiểm tra trạng thái và healthcheck của tất cả container.

## Cài self-hosted runner trên Windows

1. Cài Git for Windows và Docker Desktop; bật Linux containers và chờ Docker Desktop ở trạng thái running.
2. Vào GitHub repository: **Settings > Actions > Runners > New self-hosted runner > Windows > x64**.
3. Trong PowerShell, làm đúng các lệnh tải xuống và cấu hình GitHub hiển thị. Không cài runner bên trong thư mục repository.
4. Khi cấu hình, bảo đảm runner có các label mặc định `self-hosted`, `Windows`, `X64`.
5. Chạy thử bằng `run.cmd`. Để tự khởi động cùng Windows, chạy `config.cmd` bằng quyền Administrator và chọn chạy runner dưới dạng Windows service khi trình cấu hình hỏi.
6. Tài khoản chạy runner phải có quyền sử dụng Docker Desktop. Có thể kiểm tra bằng:

```powershell
docker version
docker compose version
```

Runner cần online liên tục để nhận job deploy. Không dùng cùng runner này cho repository không tin cậy.

## Cấu hình `.env` và GitHub Secrets

Không commit `.env` hoặc credential thật. Dùng một trong hai cách:

### Cách 1: `.env` có sẵn trên runner

Sau khi runner đã checkout repository lần đầu, tạo `backend/.env` từ template:

```powershell
Copy-Item backend/.env.example backend/.env
```

Điền đủ giá trị thật. Workflow đặt `clean: false` để giữ file ignored này giữa các lần checkout.

### Cách 2: GitHub Secret (khuyến nghị)

Tạo repository secret **`BACKEND_ENV_FILE`** tại **Settings > Secrets and variables > Actions**. Giá trị secret là toàn bộ nội dung file `backend/.env`. Khi deploy, workflow ghi secret này thành `.env` trên máy runner mà không in nội dung ra log.

Các biến bắt buộc tối thiểu theo Compose hiện tại:

```dotenv
DB_PASSWORD=...
JWT_SECRET=...
INTERNAL_SERVICE_TOKEN=...
NGROK_AUTHTOKEN=...
```

Điền thêm các credential ứng dụng trong `backend/.env.example` như Google, Cloudinary, PayOS và Groq. Có thể dùng GitHub Environment secrets nếu cần tách cấu hình `dev` và `main`; khi đó cần gắn environment tương ứng vào job `deploy`.

## Chạy pipeline

- Tạo PR vào `dev` hoặc `main`: chỉ chạy CI.
- Push/merge vào `dev` hoặc `main`: chạy CI; nếu thành công thì Windows runner tự deploy.
- Chạy local thủ công:

```powershell
Set-Location backend
docker compose config --quiet
docker compose up -d --build --wait --wait-timeout 300
docker compose ps
```

Nếu deploy lỗi, xem log bằng `docker compose logs --tail 100`. API Gateway được publish tại `http://localhost:8080` theo cấu hình mặc định.

Xem thêm hướng dẫn backend tại [backend/README.md](backend/README.md).
