# VeggiePal FE — Tech Stack & Quy ước (dành cho AI agent)

> **Đọc file này trước khi viết bất kỳ dòng code FE nào.**
> Mục tiêu: không đổi công nghệ, không đổi cách tổ chức code, không đổi giao diện (UI).
> Phạm vi: chỉ phần **Frontend** (thư mục `frontend/` của monorepo VeggiePal-Microservice). Backend không thuộc phạm vi file này.
>
> Quy tắc vàng: **không thêm thư viện mới, không đổi công cụ, không tự chế style mới** nếu chưa được người dùng đồng ý rõ ràng. Cái gì đã có thì dùng lại.

---

## 1. Công nghệ đang dùng (đúng theo `package.json`)

| Mảng | Công nghệ | Phiên bản | Ghi chú |
|---|---|---|---|
| Ngôn ngữ | **JavaScript + JSX** | ES Modules (`"type": "module"`) | **KHÔNG dùng TypeScript** (`jsconfig.json`, `components.json` có `"tsx": false`). File là `.js` / `.jsx`, không tạo `.ts` / `.tsx` |
| UI framework | **React** | ^19.2 | Function component + hooks. Không dùng class component |
| Build tool | **Vite** | ^8 | Plugin `@vitejs/plugin-react` ^6 |
| CSS | **Tailwind CSS v4** | ^4.3 | Qua `@tailwindcss/vite`. **Không có `tailwind.config.js`** — cấu hình bằng `@theme` trong CSS |
| Animation CSS | `tw-animate-css` | ^1.4 | Import trong `globals.css` |
| UI primitives | **shadcn/ui** (style `base-nova`) trên **`@base-ui/react`** | ^1.8 | **Không phải Radix.** Thêm component bằng CLI shadcn (xem mục 6) |
| Icon | **`lucide-react`** | ^1.45 | Chỉ dùng lucide. Không thêm bộ icon khác |
| Variant class | `class-variance-authority` (cva) | ^0.7 | Dùng cho variant của component |
| Gộp class | `cn` | ^0.4 | `import { cn } from "@/lib/utils"` |
| Routing | **`react-router-dom`** | ^7 | Dùng `BrowserRouter` + `<Routes>`/`<Route>` (khai báo trong `src/app/routes.jsx`) |
| Server state | **`@tanstack/react-query`** | ^5 | Cho mọi dữ liệu lấy từ API thật |
| Client state | **`zustand`** | ^5 | Cho state toàn cục phía client (auth, theme) |
| QR code | **`qrcode.react`** | 4.2.0 | Vẽ mã VietQR (`QRCodeSVG`) ở trang thanh toán tự dựng `/checkout/:orderId` |
| HTTP | **`axios`** | ^1.20 | Qua instance dùng chung `apiClient` |
| Form | **`react-hook-form`** + `@hookform/resolvers` | ^7 / ^5 | Luôn đi cùng `zodResolver` |
| Validation | **`zod`** | ^3.25 | **Zod 3** (không phải Zod 4). Schema đặt trong `schema.js` |
| Font | `@fontsource-variable/geist` + Google Fonts (Plus Jakarta Sans, Inter) | — | Xem mục 4 |
| Lint | **ESLint 10** (flat config) + `react-hooks` + `react-refresh` | — | `npm run lint` |
| Test | **`node:test`** (built-in Node) + `node:assert/strict` | — | `npm test` — chỉ dùng cho **test tạm** (xem 5.7). **Không dùng Jest/Vitest** |

### Lệnh

```bash
npm run dev       # chạy dev server (vite)
npm run build     # build production -> dist/
npm run preview   # xem bản build
npm run lint      # eslint .
npm test          # node --test "src/**/*.test.js" — chỉ chạy khi đang có file *.test.js tạm (repo không giữ test lâu dài)
```

### Biến môi trường (`.env`)

- `VITE_VEGGIEPAL_API_BASE_URL` — base URL của API gateway (vd: `http://localhost:8080/api`). Đọc bằng `import.meta.env.VITE_VEGGIEPAL_API_BASE_URL`.
- `VITE_MAPBOX_TOKEN`, `VITE_MAPBOX_STYLE` — token và style (`mapbox://styles/...`) cho bản đồ ở `/map`. Thiếu token thì trang hiện thông báo thay vì bản đồ.
- `VITE_GOOGLE_CLIENT_ID` — OAuth Client ID (Web) cho "Tiếp tục với Google" ở `/login` và `/register`. **Phải trùng `GOOGLE_CLIENT_ID` của identity-service**, và origin của FE (vd `http://localhost:5173`) phải nằm trong "Authorized JavaScript origins" của Client ID đó. Thiếu biến thì bấm nút sẽ báo chưa cấu hình.
- Biến phải có tiền tố `VITE_`. Không hardcode URL API trong code.

---

## 2. Những thứ KHÔNG được làm

- ❌ Không chuyển sang TypeScript, không thêm `.ts/.tsx`, không thêm PropTypes.
- ❌ Không thêm UI library khác (MUI, Ant Design, Chakra, Mantine, Bootstrap, v.v.).
- ❌ Không dùng styled-components / emotion / CSS Modules / SCSS. Chỉ Tailwind + `globals.css`.
- ❌ Không tạo `tailwind.config.js`, không tạo `postcss.config.js` (Tailwind v4 chạy qua plugin Vite).
- ❌ Không dùng Redux / Context để thay Zustand; không dùng SWR / `useEffect + fetch` thay React Query cho dữ liệu API mới.
- ❌ Không dùng `fetch` trực tiếp hay `axios.create` mới — luôn dùng `apiClient` (`@/shared/api/apiClient`).
- ❌ Không dùng Formik / Yup — chỉ react-hook-form + zod.
- ❌ Không dùng icon từ nguồn khác (FontAwesome, react-icons, heroicons...) — chỉ `lucide-react`.
- ❌ Không dùng Radix UI trực tiếp (project dùng `@base-ui/react`).
- ❌ Không đổi bảng màu, font, bo góc, cấu trúc layout đã có (xem mục 4).
- ❌ Không đổi test runner; không thêm `jest`/`vitest`/`@testing-library`.
- ❌ Không import đường dẫn tương đối kiểu `../../..` — dùng alias `@/`.
- ❌ Không sửa file trong `node_modules/`, `dist/`.

---

## 3. Cấu trúc thư mục & kiến trúc

Alias: **`@` → `src/`** (khai báo ở `vite.config.js` và `jsconfig.json`). Luôn `import ... from "@/..."`.

```
src/
├── main.jsx                 # entry: import globals.css + themeStore, render <App/>
├── app/
│   ├── App.jsx              # bọc AppProvider + AppRoutes
│   ├── provider.jsx         # QueryClientProvider + BrowserRouter (provider dùng chung)
│   └── routes.jsx           # TẤT CẢ route khai báo ở đây
├── assets/                  # chỉ còn video/ (video nền trang chủ). Không dùng ảnh/SVG file: icon dùng lucide-react, logo là component SVG (shared/components/Logo.jsx)
├── components/ui/           # component shadcn (button.jsx, select.jsx ...); cva variants ở ui/variants/ (button-variants.js ...)
├── features/                # MỖI TÍNH NĂNG 1 THƯ MỤC (xem bên dưới)
│   ├── auth/  admin/  blog/  chatbot/  home/  ingredient/  meal-planner/  my-content/  payment/  profile/  recipe/  restaurant-map/  video/
├── lib/                     # tiện ích dùng chung: queryClient.js, schema.js, utils.js (cn)
├── shared/                  # dùng chung nhiều feature
│   ├── api/apiClient.js     # axios instance duy nhất
│   ├── components/          # Reveal, ThemeToggle, ScrollToTop (đưa thanh cuộn về đầu trang khi đổi route, đặt trong App.jsx) ...
│   └── store/themeStore.js  # zustand theme
└── styles/globals.css       # Tailwind + design tokens (nguồn sự thật của màu/font)
```

### Cấu trúc một feature (theo feature-based architecture)

```
features/<ten-feature>/
├── api/         # <ten>Api.js  — hàm gọi API (dùng apiClient)
├── components/  # component riêng của feature (PascalCase.jsx)
├── hooks/       # useXxx.js — React Query hooks / logic state
├── pages/       # <Ten>Screen.jsx — màn hình cấp route
├── store/       # zustand store (nếu cần)
├── data/        # (chỉ khi cần) lựa chọn tĩnh của giao diện, vd. meal-planner/data/mealPlannerOptions.js. KHÔNG đặt dữ liệu giả ở đây
├── utils/       # hàm thuần (file *.test.js chỉ tồn tại tạm lúc test, test xong thì xóa)
├── queryKeys.js # khóa cache React Query của feature
└── schema.js    # zod schema riêng (hoặc dùng src/lib/schema.js)
```

**Quy tắc đặt tên**
- Component / Screen: `PascalCase.jsx` (`LoginForm.jsx`, `ProfileScreen.jsx`).
- Hook: `useXxx.js` (`useProfile.js`). Store: `xxxStore.js` với hook `useXxxStore`.
- API: `xxxApi.js`, hàm export dạng `getXxx`, `updateXxx`, `createXxx`...
- Test tạm: `xxx.test.js` đặt **cạnh** file được test, **xóa sau khi test xong** (xem 5.7).
- Thư mục: `kebab-case` (`meal-planner`, `restaurant-map`).
- Feature mới → tạo thư mục mới trong `features/`, đừng nhét vào feature khác.
- **Mọi thứ chỉ dành cho ADMIN nằm trong `features/admin/`** (không tạo feature riêng ở ngoài). Trang (`pages/`), khung (`components/AdminLayout.jsx`) và form dùng chung của khu admin để ở thư mục gốc của `admin/`. Khi một chức năng admin có nhiều file thì tạo **thư mục con theo chức năng** trong `admin/`, bên trong dùng lại cấu trúc `api/ hooks/ components/ utils/ queryKeys.js`. Hiện có: `admin/monitoring/` (giám sát AI). Danh mục và nguyên liệu dùng chung với người dùng thường nên vẫn nằm ở `blog/` và `ingredient/`, trang quản lý của chúng ở `admin/pages/`.
- Route mới → thêm vào `src/app/routes.jsx`; trang cần đăng nhập thì bọc `<ProtectedRoute>`.

### Trạng thái từng feature (không còn dữ liệu mẫu: FE chỉ làm những gì BE đã có API)

| Feature | Route | Dữ liệu |
|---|---|---|
| auth | `/login` `/register` | API thật (`authApi.js`): đăng nhập, đăng ký và **đăng nhập Google** (`POST /auth/google`, thư viện `@react-oauth/google`, component `GoogleSignInButton`: nút kính mờ của app phủ nút Google thật trong suốt để lấy ID token; BE tự tạo tài khoản nếu chưa có, phiên lưu lâu dài). Message lỗi của identity-service là tiếng Anh nên `authApi.js` dịch sang tiếng Việt theo `code` bằng `toAuthMessage` (`utils/authErrors.js`): đăng nhập sai (BE trả 1008 cho cả sai email lẫn sai mật khẩu) hiện "Email hoặc mật khẩu không đúng", 1002 email đã đăng ký, 1003–1006 / 1010 / 1018 lỗi dữ liệu, 1019 Google; mã lạ dùng câu mặc định của từng hàm, 5xx báo lỗi máy chủ, mất kết nối báo "Không kết nối được máy chủ". Quên mật khẩu / OTP đã gỡ khỏi FE vì BE chưa có endpoint |
| profile | `/profile` | API thật + React Query (`profileApi.js`, `useProfile`...). Ngày sinh, giới tính (`gender`: MALE / FEMALE / OTHER) và mức độ vận động (`activityLevel`: SEDENTARY / LIGHT / MODERATE / ACTIVE / VERY_ACTIVE) nhập ở form chỉ số sức khỏe (`EditHealthForm`, qua khối `CalorieProfileFields`) cùng chiều cao, cân nặng, KHÔNG nằm ở thẻ "Thông tin cá nhân" (thẻ này chỉ còn họ tên và số điện thoại, `usePersonalInfoForm` không gửi các trường kia nên BE giữ nguyên). Ba trường này BE dùng để tính nhu cầu calo của thực đơn nên meal-planner dẫn về đây khi thiếu (lỗi 6020); chúng thuộc hồ sơ chứ không thuộc bản ghi sức khỏe nên form lưu chúng qua `PATCH /users/me` (chỉ gửi trường đã chọn và khác hồ sơ vì BE không nhận chuỗi rỗng và không có cách xóa về trống; `GENDER_OPTIONS` / `ACTIVITY_LEVEL_OPTIONS` ở `editProfileConstants.js`), còn chiều cao, cân nặng qua `POST /nutrition/me/health-records`; chỉ đổi hồ sơ mà chiều cao, cân nặng giữ nguyên thì chỉ cập nhật hồ sơ, không tạo thêm bản ghi trùng. Liên kết "Cập nhật hồ sơ" ở meal-planner gắn `state` (`profileFixState` ở `meal-planner/utils/mealPlan.js`: `missingFields`, `returnTo`, `returnLabel`), trang `/profile/edit` đọc bằng `readProfileFixState` (`profile/utils/profileFixState.js`, lọc giá trị hợp lệ, `returnTo` chỉ nhận đường dẫn nội bộ): thẻ chỉ số sức khỏe cuộn tới giữa màn hình, hiện dòng nhắc và làm nổi các ô còn trống (hết nổi khi điền), "Lưu thông tin" / "Hủy" quay lại trang thực đơn thay vì `/profile`, và form chỉ số hiện liên kết quay lại sau khi ghi nhận. Nút "Ghi nhận" của form chỉ số nằm ở đầu thẻ, cạnh nhãn "Cá nhân hóa": `EditHealthCard` giữ một phần tử chỗ chứa (`submitSlot`), `EditHealthForm` đặt nút vào đó bằng `createPortal` và gắn với form qua thuộc tính `form` nên trạng thái "Đang ghi…" và Enter trong ô nhập vẫn hoạt động. Năm ô của form (chiều cao, cân nặng, ngày sinh, giới tính, mức vận động) cùng cao `h-10`; ô chọn dùng `SelectField` `variant="compact"` (thấp, chữ nhỏ, bo `rounded-2xl`), ô giới tính hẹp hơn và ô mức vận động rộng nhất (lưới `1fr / 0.75fr / 1.4fr`), nhãn mức vận động giữ tối đa khoảng 34 ký tự để hiện đủ. Lịch sử chỉ số sức khỏe ở `/profile/edit` (`EditHealthHistory`) có nút "Sửa" từng dòng (`PUT /nutrition/me/health-records/:id` qua `useUpdateHealthRecord`, làm mới cả chỉ số mới nhất lẫn biểu đồ BMI); BE giữ nguyên thời điểm ghi nhận nên sửa bản ghi cũ không làm nó thành "mới nhất". Lỗi identity (10xx) và nutrition (20xx) được dịch sang tiếng Việt theo `code` ngay trong `profileApi.js` (kèm 401 / 403 / 413 / 429 / 503 khi không có mã), `getLatestHealthRecord` coi 404 hoặc mã 2005 là chưa có bản ghi |
| home | `/` | Món chay nổi bật: API thật (`useRecipes` + `useRecipeNutrition` + `usePublicUsers`); Gợi ý dành riêng cho bạn: API thật (ai-service qua gateway `GET /ai/recommendations` kèm lý do đề xuất, yêu cầu đăng nhập; lỗi 60xx và 401 / 429 / 503 dịch sang tiếng Việt trong `recommendationApi.js`, 429 là hết hạn mức token AI trong ngày) |
| meal-planner | `/meal-planner` | API thật (ai-service qua gateway, cần đăng nhập): tạo thực đơn 7 ngày × 3 bữa bằng AI (`POST /ai/meal-plans`, nguyên liệu chọn từ `/ingredients`, khẩu vị; bắt buộc chọn mục tiêu giảm / duy trì / tăng cân bằng 3 nút → `goalType` (`GOAL_OPTIONS`), BE trả 400 / 6000 nếu thiếu; `healthGoal` gửi BE là nhãn của mục tiêu (`buildHealthGoalText`) vì BE bắt buộc `healthGoal` không rỗng (đã bỏ ô "Mô tả thêm" vì không ảnh hưởng gì tới kết quả); mục tiêu dinh dưỡng mỗi ngày mặc định do BE tự tính theo chỉ số sức khỏe + ngày sinh / giới tính / mức vận động và FE chỉ xem trước qua `GET /ai/meal-plans/nutrition-target?goalType=` (`getNutritionTarget`, hook `useNutritionTarget`, thẻ `NutritionTargetCard`: BMR, TDEE, calo mục tiêu, khoảng đạm / tinh bột / béo, kèm câu cố định "Mục tiêu calo chỉ là gợi ý, không thay thế tư vấn của chuyên gia dinh dưỡng" vì BE không trả câu này); phần "Tự đặt mục tiêu dinh dưỡng riêng" (`NutritionTargetFields`) điền ô nào thì gửi `dailyNutritionTarget` thay hẳn mục tiêu tự tính và BE không đọc hồ sơ nữa; thẻ gợi ý có nút "Dùng làm mục tiêu riêng để chỉnh" (điền sẵn 8 ô từ kết quả BE và mở phần tự đặt) và "Quay lại mục tiêu tự tính" (xóa các ô). Hồ sơ thiếu ngày sinh / giới tính / mức vận động hoặc dưới 18 tuổi thì `profileTargetIssue` báo ngay trên thẻ, không gọi API và khóa nút tạo khi chưa tự đặt mục tiêu riêng; hồ sơ chưa tải xong hoặc tải lỗi thì để BE quyết định. Ô nhập số hiểu cả "3,000" / "3.000" là 3000 lẫn "1500,5" là 1500,5 (`parseTargetNumber`; nhóm đúng 3 chữ số và không bắt đầu bằng 0 mới tính là dấu phân cách hàng nghìn, nên "0,500" vẫn là 0,5)), danh sách thực đơn đã lưu, xem theo ngày, đổi món (`POST /ai/meal-plans/:id/replace`); tên/ảnh món lấy qua `GET /recipes/:id`; thẻ BMI từ nutrition-service. Cần có chỉ số sức khỏe mới tạo được thực đơn (BE lỗi 6010) nên form khóa nút và dẫn tới `/profile/edit` khi chưa có; nguyên liệu có sẵn chỉ là ưu tiên; món có nhãn "Khẩu phần ×N" khi BE co giãn khẩu phần (`servingMultiplier`); lỗi 6010/6011/6020/6021 và 6999 (BE lỗi không rõ, "Uncategorized error") được dịch trong `mealPlanApi.js`, lỗi ném ra mang theo `error.code`. 6020 (hồ sơ thiếu ngày sinh / giới tính / mức vận động) và 6021 (dưới 18 tuổi) chỉ xảy ra khi BE tự tính mục tiêu (không gửi `dailyNutritionTarget` / `customTarget`) và không tốn lượt: `NutritionTargetCard` hiện lỗi kèm nút dẫn tới `/profile/edit` (với 6021 thì gợi ý tự đặt mục tiêu riêng) và form khóa nút tạo khi chưa tự đặt mục tiêu riêng. Mã 6020 / 6021 của ai-service đang trùng số với 6020 / 6021 của video (`videoJobApi.js`) nhưng mỗi API có bảng dịch riêng nên không nhầm. Đặt mục tiêu dinh dưỡng mà một ngày vẫn lệch thì BE không báo lỗi (đã bỏ mã 6012) mà đánh dấu ngày đó bằng `targetMet=false` (chỉ xét calo trong `[minCalories, maxCalories]`, không còn dung sai 15%) + `targetDeviations` (liệt kê mọi chất ngoài khoảng, kể cả khi `targetMet=true`; cảnh báo vàng chỉ khi `targetMet` không phải true, còn calo đạt mà đạm / tinh bột / béo lệch thì `dayMacroNotes` cho một dòng lưu ý nhẹ màu trung tính ở `TodayMeals` và `EditMealDialog`, không đánh dấu ngày là lỡ mục tiêu): FE hiện cảnh báo trong `TodayMeals` (kèm chấm cảnh báo ở nút chọn ngày) và toast "X/7 ngày chưa đạt" sau khi tạo (`dayTargetDeviations`, `countMissedDays` ở `utils/mealPlan.js`). Tên mặc định của thực đơn là cả tuần T2 - CN chứa ngày tạo ("Thực đơn 12/10 - 18/10", `defaultPlanName`); tiêu đề ngày kèm ngày cụ thể "Thứ Năm (15/10)" tính theo tuần chứa `createdAt` (`planDayDate`), "Hôm Nay" chỉ hiện khi ngày đó đúng là hôm nay. Yêu thích theo cả thực đơn (nút "Yêu thích" cạnh danh sách chọn thực đơn, `POST/DELETE /ai/meal-plans/:id/favorite`, cờ `isFavorite` có sẵn trong danh sách, thực đơn yêu thích có trái tim đỏ trước tên trong danh sách chọn; không còn tim ở từng thẻ món). Nút "Cập nhật theo chỉ số mới" (`HealthUpdateButton`) gọi `POST /ai/meal-plans/:id/update-from-health`: `confirm=false` để xem trước (mục tiêu mới + so sánh trung bình mỗi ngày trước / sau, không lưu), bấm "Áp dụng" mới gọi `confirm=true` để lưu, BE giữ bản cũ trong lịch sử phiên bản và thay mục tiêu dinh dưỡng của thực đơn bằng mục tiêu tính lại từ chỉ số sức khỏe theo `goalType` đã lưu của thực đơn (`MealPlan.goalType`, null với thực đơn cũ thì BE tự đoán từ `goal`; hộp thoại ghi rõ mục tiêu đó). Mục tiêu của thực đơn hiện thành nhãn (Giảm cân / Duy trì / Tăng cân) kèm mô tả thêm cạnh các nút ở `TodayMeals` và dạng "Giảm cân · ăn thanh đạm" trong danh sách yêu thích (`planGoalNote`, `planGoalSummary`); thực đơn cũ chưa có `goalType` vẫn hiện nguyên chữ `goal`. Khẩu phần `servingMultiplier` giờ riêng từng bữa, trong khoảng 0,75 - 2,0 (BE chia ngân sách calo sáng 25% / trưa 40% / tối 35%). "Đổi món" và "Cập nhật theo chỉ số mới" đều làm BE tính lại khẩu phần các bữa nên khẩu phần đã tự chỉnh (`UPDATE_SERVING`) bị đặt lại: hộp thoại cập nhật có dòng cảnh báo, còn "Đổi món" hỏi xác nhận (`AlertDialog` trong `TodayMeals`, hàm `requestReplace`) khi thực đơn từ phiên bản 2 trở đi (đã sửa tay hoặc cập nhật theo chỉ số, đổi món bằng AI không tạo phiên bản), phiên bản 1 thì đổi luôn. Thực đơn cũ chưa có `goalType` (tạo trước khi BE cập nhật dữ liệu dinh dưỡng) có dòng nhắc số calo có thể chưa chính xác kèm liên kết "Tạo thực đơn mới". Hộp thoại này còn cho tự đặt mục tiêu riêng (`customTarget`, dùng lại `NutritionTargetFields`, BE dùng thay hẳn mục tiêu tính tự động, chất bỏ trống thì không bị giới hạn) và ghi chú thay đổi (`changeSummary`, tối đa 200 ký tự, hiện ở mục Lịch sử): đổi mục tiêu thì phải bấm "Xem trước lại" mới được "Áp dụng", vì bản lưu phải dùng đúng mục tiêu của bản xem trước (`sameTarget`, `buildHealthUpdateBody` ở `utils/mealPlan.js`). Mỗi thẻ món có nút "Tự chọn món / khẩu phần" (`EditMealDialog`): chọn món từ danh sách gợi ý (công thức đã đăng, bỏ các món đang có trong ngày, kèm kcal ước tính) và/hoặc khẩu phần, bấm "Xem trước" (`POST /ai/meal-plans/:id/preview-edit`, so sánh dinh dưỡng cả ngày, cảnh báo nếu lệch mục tiêu) rồi "Lưu thay đổi" (`POST /ai/meal-plans/:id/edit`, action `REPLACE` hoặc `UPDATE_SERVING`); chỉ sửa 3 bữa sẵn có, không thêm / xóa bữa; lỗi 6018 / 6019 khi món không chay / chứa dị ứng. Nút "Lịch sử" (`PlanVersionsButton`) xem các phiên bản cũ của thực đơn (`GET /ai/meal-plans/:id/versions`, chỉ xem, chưa có API khôi phục; đổi món bằng AI không tạo phiên bản): đầu hộp thoại là phiên bản hiện tại lấy mới bằng `GET /ai/meal-plans/:id`, bấm "Xem nội dung" ở một bản cũ để xem 7 ngày của bản đó (`GET /ai/meal-plans/:id/versions/:version`, lỗi 6017 nếu không có số phiên bản đó). Nút "Yêu thích của tôi" (`FavoritePlansButton`) mở hộp thoại danh sách thực đơn yêu thích phân trang 5 mục/trang (`GET /ai/meal-plans/favorites?page&size`, mới yêu thích trước); mỗi mục có "Xem chi tiết" (`GET /ai/meal-plans/favorites/:id`, xem 7 ngày) và "Mở trên trang" (chọn thực đơn đó ở trang). Xem nội dung một thực đơn / phiên bản dùng chung `PlanDaysPreview` (mỗi ngày một dòng, bấm để xem 3 bữa, tên món lấy qua `GET /recipes/:id` chỉ khi mở ngày đó); bật / tắt yêu thích làm mới cache danh sách yêu thích (`mealPlanKeys.favoritesRoot`). Form tạo thực đơn hiện giới hạn của gói (`mealPlansPerMonth` từ `GET /subscriptions/me`: FREE 2, PLUS 8, PRO 20 thực đơn mỗi tháng) kèm liên kết `/pricing`; gói 0 lượt thì khóa nút và mời nâng cấp. BE chưa có API số lượt đã dùng nên chỉ hiện được tổng lượt, không hiện được số còn lại. Đã gỡ các thẻ Nước & Vận Động và thẻ lời khuyên tĩnh vì BE chưa có API; lựa chọn tĩnh của form (khẩu vị, nhãn macro) nằm ở `data/mealPlannerOptions.js` |
| restaurant-map | `/map` | API thật: quán chay quanh vị trí người dùng (`GET /restaurants/nearby` của location-service, công khai) trên bản đồ Mapbox (`react-map-gl`), có gom cụm, lọc theo tên, chọn bán kính. Cần `VITE_MAPBOX_TOKEN`, `VITE_MAPBOX_STYLE` |
| video | `/videos`, `/videos/:videoId` (đăng / sửa video mở bằng popup) | API thật (`videoApi.js` + `useVideos` + `useVideoMutations`): danh sách video đã duyệt (`GET /videos`, lọc theo danh mục, phân trang "Xem thêm"), chi tiết video (`GET /videos/:id`, player tự động chọn iframe embed cho YOUTUBE hoặc thẻ `<video>` mp4 cho UPLOAD, nạp tác giả qua `usePublicUsers`), đăng video multipart có thanh tiến trình (tệp .mp4 ≤ 30MB hoặc YouTube link), sửa video (`PUT /videos/:id`), kiểm duyệt DRAFT / PENDING / PUBLISHED / REJECTED / BANNED. Bình luận / vote / lưu video chưa có nên không hiển thị (BE chưa hỗ trợ targetType=VIDEO). **Bóc tách công thức từ video bằng AI** (ai-service qua gateway): (1) Bóc tách video đã đăng: tại `/videos/:videoId`, hook `useVideoRecipe` phục vụ nút "Bóc tách công thức AI" ở `VideoMetaHeader` và thẻ `AiSummaryCard`. Chỉ áp dụng cho video `UPLOAD` đã `PUBLISHED`; gọi `POST /ai/videos/process-existing { videoId }` (trừ 1 lượt của thành viên; kết quả dùng chung, đã có sẵn hoặc đang xử lý thì không trừ lượt). Xem công thức dùng chung qua `GET /ai/videos/by-video/:videoId` (công khai permitAll, khách chưa đăng nhập cũng xem được kết quả khi đã ready; chưa có công thức thì khách thấy lời mời đăng nhập để bóc tách). 8 trạng thái của `useVideoRecipe`: `loading` (đang tải trạng thái ban đầu), `unsupported` (video YouTube chưa hỗ trợ, mã 6021), `login` (khách chưa đăng nhập khi chưa có công thức), `none` (chưa có công thức, thành viên có thể bóc tách), `processing` (đang bóc tách, mã 6022 / HTTP 409, tự động poll mỗi 4s), `failed` (thất bại, mã 6023 / HTTP 422, lượt được hoàn lại), `ready` (đã có kết quả: tiêu đề, nguyên liệu, các bước), `error` (lỗi mạng/server). Lượt theo gói: FREE 0, PLUS 3, PRO 8 mỗi tháng (theo `videosPerMonth` từ `GET /subscriptions/me`). Mã lỗi 6020 đến 6024: 6020 hàng đợi đầy, 6021 video YouTube chưa hỗ trợ, 6022 đang xử lý, 6023 bóc tách thất bại, 6024 âm thanh thiếu thông tin công thức món ăn; kết quả giữ 30 ngày (sau 30 ngày BE tự dọn dẹp hoặc trả 404). (2) Bóc tách tệp độc lập & lịch sử: gửi tệp qua `POST /ai/videos/process` (multipart `file` ≤ 100MB, ≤ 30 phút, cần đăng nhập); lịch sử bóc tách của tôi lấy qua `GET /ai/videos` (hiển thị ở tab "Bóc tách" tại `/my-content`), job tạo từ video đã đăng có `sourceVideoId` liên kết ngược về video. |
| blog | `/blog`, `/blog/:blogId` (viết / sửa bài mở bằng popup) | API thật: feed (tìm kiếm/sắp xếp/lọc danh mục trên URL), chi tiết bài, bài liên quan, danh mục, bình luận, vote, viết/sửa bài + ảnh bìa; bảng vàng, chủ đề hot, thử thách 7 ngày đã gỡ vì BE chưa có API. Chủ bài (kèm token) mở được bài chưa đăng qua `GET /blogs/:id` nên sửa được bài DRAFT/PENDING/REJECTED (trừ BANNED); trang đọc bài chưa đăng hiện nhãn trạng thái và ẩn vote, bình luận, bài liên quan. Lỗi blog-service dịch theo `code` trong `blogErrors.js` (danh mục 3001–3008, bài viết 3010–3015, ảnh bìa 3020–3022, bình luận 3030–3037, vote 3040–3041, kiểm duyệt AI 3050–3052: đăng / gửi duyệt khi ai-service không khả dụng thì báo "Hệ thống kiểm duyệt tạm thời không khả dụng") |
| my-content | `/my-content` (tab trên URL `?tab=videos` / `recipes` / `extractions`) | API thật: bài viết của tôi (`/blogs/me`), công thức của tôi (`/recipes/me`) và video của tôi (`/videos/me`), kèm sửa / gửi duyệt / đăng / xóa (bài viết: sửa được mọi trạng thái trừ BANNED, bấm vào bài để đọc cả khi chưa đăng). Tab "Bóc tách" (`MyVideoJobList`): lịch sử AI bóc tách công thức từ video (`GET /ai/videos`), nút góc phải "Bóc tách video" mở hộp thoại tải tệp lên (`UploadVideoJobDialog`) thay vì chuyển trang, dòng hoàn tất có "Xem kết quả" (`VideoJobResultDialog`); chi tiết xem dòng video |
| recipe | `/recipes`, `/recipes/:recipeId` (tạo / sửa công thức mở bằng popup) | API thật: tạo / sửa công thức (chọn nguyên liệu từ `/ingredients`, ô chọn `IngredientPicker` hiện cả `description` của nguyên liệu vì BE ghi ở đó trạng thái sống / chín / khô / tươi, chọn nhầm thì calo lệch gần 3 lần; ô chọn này dùng chung với form tạo thực đơn); danh sách công khai hiện ở trang chủ. `GET /recipes/:id` kèm token thì chủ công thức / ADMIN đọc được bản nháp (nạp form sửa, xem chi tiết), người khác nhận 404; công thức ARCHIVED (đã xóa) hoặc HIDDEN không sửa / đăng / xóa được (lỗi 4108). Lỗi recipe-service (1008/1009, 4100-4108) được dịch trong `recipeApi.js`, lỗi nguyên liệu trong `ingredientApi.js`. Dinh dưỡng mỗi khẩu phần (kcal, đạm, carb, béo) tính tại FE từ dinh dưỡng trên 100g mà BE nhúng sẵn trong `recipe.ingredients[]` ở cả danh sách lẫn chi tiết (`calcRecipeNutrition`; hook `useRecipeNutrition` trả `{ nutritionById, gapById }`, không còn gọi `GET /ingredients/:id` cho từng nguyên liệu). Chỉ quy đổi được đơn vị khối lượng (gram, kg, mg); công thức có nguyên liệu tính bằng muỗng / quả / ml thì không tính và trang chi tiết nêu rõ đơn vị nào gây ra (`nutritionGapHint`), muốn tính đủ phải nhờ BE trả dinh dưỡng sẵn. Trang chi tiết gắn nhãn "Dễ gây dị ứng" / "Không thuần chay" cho từng nguyên liệu và cảnh báo phía trên danh sách theo cờ `allergen` / `vegan` của BE (`utils/recipeSafety.js`); `allergen` chỉ là cờ chung, không nói dị ứng gì nên không so được với dị ứng cụ thể của người dùng, chỉ dẫn tới `/profile/edit` để kiểm tra |
| admin | `/admin`, `/admin/categories`, `/admin/ingredients`, `/admin/moderation`, `/admin/ai-monitoring`, `/admin/payments` | API thật, chỉ role ADMIN (`AdminRoute`): tổng quan, quản lý danh mục (`/categories`), nguyên liệu (`/ingredients`), kiểm duyệt nội dung (ai-service: hàng đợi `GET /ai/admin/moderation` với các case REVIEW_REQUIRED, duyệt/từ chối `PUT /ai/admin/moderation/:id` kèm lý do, BE tự đồng bộ về blog-service; nút "Bỏ qua" gọi `DELETE /ai/admin/moderation/:id?reason=` (`useDismissModeration`) chỉ đưa case ra khỏi hàng đợi, nội dung gốc KHÔNG đổi trạng thái, khác với Từ chối; case đã được xử lý trước đó thì BE trả 6013 và FE tải lại hàng đợi) và giám sát AI (ai-service qua gateway: `GET /ai/admin/monitoring/summary`, `/logs/search`, `/models`, `/limits`). ADMIN đăng nhập xong vào thẳng `/admin` (`resolvePostLoginPath`). **Thanh toán** (`/admin/payments`, thư mục `admin/payments/`, payment-service qua gateway `/api/admin/payments/**`): thẻ tổng quan (`GET /summary`), phân bố trạng thái / gói (`GET /statistics`), doanh thu theo ngày hoặc tháng vẽ bằng thanh CSS màu `chart-1` (`GET /revenue?groupBy=DAY|MONTH`) và bảng đơn hàng lọc theo trạng thái, phân trang 20 đơn / trang, xem chi tiết (`GET /orders`, `GET /orders/:id`). Bộ lọc chung từ ngày / đến ngày / gói: ngày nhập vào đổi thành Instant ISO giờ địa phương (`toInstant`, ngày kết thúc lấy đến 23:59:59.999), chặn sẵn khi từ ngày lớn hơn đến ngày vì BE báo lỗi 400 |
| chatbot | `/chatbot` (công khai) | API thật (ai-service, `chatbotApi.js` + `useChatbot` React Query): thành viên chat nhiều lượt + xem/xóa lịch sử hội thoại (`/ai/chat`, `/ai/chat/conversations`); khách chưa đăng nhập dùng thử qua `/ai/chat/guest-sessions` + `/ai/chat/guest` (có giới hạn lượt/ngày, phiên lưu `sessionStorage`). Thành viên thấy gói và số lượt còn lại trong ngày (`remainingRequests` của BE trên `chatPerDay` của `GET /subscriptions/me`: FREE 5, PLUS 20, PRO 50 lượt mỗi ngày) ở thanh dưới tiêu đề, chưa gửi câu nào thì chỉ hiện giới hạn của gói |
| payment | /pricing, /checkout/:orderId, /payment/success, /payment/cancel, /payment/history | API thật (payment-service qua gateway, tích hợp payOS): xem các gói thành viên công khai (GET /payments/plans), tạo đơn thanh toán payOS (POST /payments/checkout, lưu order.id tạm ở sessionStorage, chuyển hướng cổng payOS), trang thành công (/payment/success, polling GET /payments/orders/:id xác nhận webhook, không tin query param payOS, cập nhật gói ngay), trang hủy (/payment/cancel), lịch sử đơn hàng (/payment/history, GET /payments/history), thông tin gói hiện tại (GET /subscriptions/me, hiển thị ở header menu và trang profile). Bảng dịch lỗi riêng trong paymentApi.js (6001-6004, 1008/401). | **Cập nhật:** trang `/checkout/:orderId` (`CheckoutScreen`, lấy orderId từ `useParams`, F5 không mất) tự vẽ QR bằng `qrcode.react`, poll `GET /payments/orders/:id` mỗi 2,5s khi PENDING (PAID -> /payment/success, CANCELLED -> /pricing, FAILED -> báo lỗi), đếm ngược `expiredAt`, nút "Tạo lại" khi hết hạn, "Huỷ thanh toán" gọi `cancelOrder` (`POST /payments/orders/:id/cancel`, hook `useCancelOrder`; mã lỗi 6008/6009). Không còn chuyển hướng sang trang hosted payOS.

**Popup tạo / sửa nội dung:** viết bài, tạo công thức và đăng video (cả tạo mới lẫn sửa) là popup (`Dialog`), không còn route riêng `/blog/new`, `/recipes/new`, `/videos/new` hay `/…/:id/edit`. Trạng thái nằm ở `shared/store/contentFormStore.js` (`{ kind: "blog" | "recipe" | "video", id?, video? }`), popup được dựng một lần ở `app/ContentFormHost.jsx` (mỗi loại có `BlogFormDialog`, `RecipeFormDialog`, `VideoFormDialog`), nút nào cũng mở bằng `useContentForm().openForm(kind, { id })` (`shared/hooks/useContentForm.js`; khách chưa đăng nhập được đưa sang `/login` rồi quay lại trang cũ). Sau khi lưu form chỉ đóng popup và làm mới cache, không chuyển trang.

Không dựng UI hay dữ liệu giả cho thứ BE chưa có. Khi BE bổ sung API mới thì thêm `*Api.js` + React Query hook theo mẫu của `profile`, rồi mới thêm giao diện.

---

## 4. Hệ thống UI / Design (BẮT BUỘC giữ nguyên)

Nguồn sự thật: **`src/styles/globals.css`**. Màu thương hiệu lấy từ Figma "VeggiePalApp".

### 4.1. Dùng token, không dùng hex cứng

Luôn dùng class Tailwind map tới token (đã khai báo trong `@theme inline`):

| Mục đích | Class Tailwind | Light | Dark |
|---|---|---|---|
| Màu thương hiệu (xanh lá) | `bg-brand` `text-brand` `border-brand` | `#2e7d32` | `#66bb6a` |
| Chữ trên nền brand | `text-brand-foreground` | `#fff` | `#08260b` |
| Nền xanh nhạt | `bg-brand-soft` | `#e6f2e3` | `#17321a` |
| Brand phụ (gradient) | `to-brand-2` | `#8bc34a` | `#aed581` |
| Xanh đậm (chữ logo, tiêu đề nhấn) | `text-brand-deep` | `#1b5e20` | `#a5d6a7` |
| Cảnh báo | `text-warning` `bg-warning` | `#f0883e` | `#ffa361` |
| Nguy hiểm / lỗi | `text-destructive` `bg-destructive/10`, `text-danger` | — | — |
| Chữ chính (đậm) | `text-ink` | `#1b2b1c` | `#e6ede6` |
| Chữ nội dung | `text-body` | `#435346` | `#c4d2c5` |
| Chữ phụ / mờ | `text-subtle` | `#6b7a6c` | `#a0b3a2` |
| Nền trang | `bg-canvas` | trong suốt (lộ gradient `--page-bg` của `<body>`, nền gốc `#f7f9f6`) | trong suốt (nền gốc `#0e150f`) |
| Nền ô nhập / khối phụ | `bg-surface` | `#eff5ec` | `#17261a` |
| Nền card | `bg-card` | trắng | `#162218` |
| Viền | `border-border` | — | — |
| Màu biểu đồ | `chart-1..5` | xanh lá / xanh dương / tím / cam / xanh nhạt (carb / nước / vận động / béo / đạm) | — |

- Dark mode: class `dark` trên `<html>` (variant `dark:` của Tailwind). **Mọi UI mới phải hiển thị đúng ở cả light lẫn dark** — ưu tiên dùng token (tự đổi màu theo theme) thay vì màu cố định.
- Code cũ có vài hex cứng (`#E8F5E9`, `#EF6461`, `#E8ECFB`...) kèm biến thể `dark:` — chỉ giữ ở code cũ, **code mới nên dùng token**.
- Theme do `useThemeStore` (zustand) quản lý, lưu `localStorage` key `theme`; nút đổi theme là `ThemeToggle` (hiệu ứng circular reveal bằng View Transitions).

### 4.2. Font

- **Tiêu đề (`h1,h2,h3`, class `font-heading` / `font-display-serif`)**: **Plus Jakarta Sans** (sans hình học, có tiếng Việt) — nạp qua Google Fonts trong `index.html`. Tên biến `--font-display-serif` là tên cũ, giữ nguyên để không phải đổi class.
- **Chữ thường (`font-sans`, mặc định `html`)**: **Geist Variable** (`@fontsource-variable/geist`).
- **Trang chủ (`font-home-sans`)**: **Inter**.
- Menu nav dùng `font-display-serif`. Không thêm font mới.

### 4.3. Bo góc, khoảng cách, bóng

- Radius gốc `--radius: 0.75rem`; scale `rounded-sm … rounded-4xl` theo token.
- **Nút: bo tròn hẳn (`rounded-full`) là mặc định.** Nút cần bo khác thì truyền `className="rounded-xl"`.
- **Card/section**: `rounded-3xl border border-border bg-card p-5 shadow-sm sm:p-6`.
- **Ô input (trang thường)**: `h-11 w-full rounded-xl border border-border bg-surface px-3.5 text-sm text-ink outline-none transition placeholder:text-subtle focus:border-brand/40 focus:ring-2 focus:ring-brand/15 aria-[invalid=true]:border-destructive/50 aria-[invalid=true]:ring-2 aria-[invalid=true]:ring-destructive/20`
- **Ô input (màn auth, nền tối/ảnh)**: gạch chân, trong suốt, chữ trắng, class `auth-input` (có xử lý autofill trong `globals.css`).
- **Kính mờ**: class `glass` / `glass-strong` (`@utility` trong `globals.css`, dùng biến `--glass-*`) cho header, banner, thẻ nổi. Banner trang dùng `GlassBanner` + `GlassPanel` + `GlassChip` (`@/shared/components/GlassBanner`): nền gradient xanh nhạt, icon lucide mờ ở bên phải, thẻ kính nổi ở góc phải — không dùng ảnh. Nền trang là gradient `--page-bg` trên `<body>`; `--canvas` trong suốt để `bg-canvas` lộ gradient đó.
- **Header**: `sticky top-3 sm:top-4 z-30`, pill `glass-strong rounded-full`. Dưới `lg` nav ẩn và thay bằng nút menu (hamburger) mở panel kính mờ liệt kê các mục. Bên phải: khách thấy icon vương miện (Gói dịch vụ) + chữ Đăng Nhập / Đăng Ký; người đã đăng nhập thấy **icon avatar mở dropdown** (không có chuông thông báo vì BE chưa có API thông báo) (shadcn `DropdownMenu`: hồ sơ, nội dung của tôi, gói, lịch sử thanh toán, đăng xuất). Nút `ThemeToggle` không nằm trên header mà là nút tròn nổi ở góc dưới bên phải màn hình (`fixed bottom-4 right-4 sm:bottom-6 sm:right-6`, render trong `AppHeader`, đặt ngoài pill vì `backdrop-blur` làm `fixed` bị kẹt trong pill). Avatar ở nút và đầu menu lấy từ `useProfile` (cache `profileKeys.me`, `staleTime` 5 phút) vì `/auth/login` không trả `avatarUrl`; đổi avatar ở `/profile/edit` ghi thẳng vào cache đó nên header đổi theo ngay, ảnh rỗng/lỗi thì hiện icon người.
- **Khung nội dung trang**: `mx-auto w-full max-w-6xl` (hoặc `max-w-[1280px]`) `px-4 sm:px-6 lg:px-8`, nền trang `bg-canvas`, `min-h-dvh`.
- Icon: `lucide-react`, kích thước `size-4` / `size-5`; trong `<Button>` dùng `size-*` thay vì `h-* w-*`.
- Responsive: mobile-first, breakpoint `sm/md/lg` của Tailwind (nav ẩn dưới `lg`, thay bằng menu hamburger).
- Tôn trọng `prefers-reduced-motion` (đã xử lý trong `globals.css`).

### 4.4. Button — luôn dùng `@/components/ui/button`

```jsx
import { Button } from "@/components/ui/button";
<Button variant="default" size="md">…</Button>
```

- **variant**: `default` (xanh brand) · `outline` · `secondary` · `soft` · `ghost` · `destructive` · `link` · `gradient` (CTA/submit ở auth) · `glass` (trên nền tối/ảnh).
- **size**: `xs` `sm` `default` `md` `lg` `xl` `icon` `icon-xs` `icon-sm` `icon-lg`.
- Style `<Link>` giống nút: `className={buttonVariants({ variant, size })}` (import từ `@/components/ui/variants/button-variants`).
- **Không tạo `<button>` tự style** để thay `<Button>` cho nút mới (trừ các icon-toggle nhỏ như nút hiện/ẩn mật khẩu).

### 4.5. Layout & mẫu trang

- Trang sau đăng nhập luôn có khung: `<AppHeader />` + `<main>` (import từ `@/shared/components/`), bọc trong `<div className="min-h-dvh bg-canvas">`. **Chỉ trang chủ (`HomeScreen`) có `<AppFooter />`**, các trang khác không dùng footer.
- Section xuất hiện dần khi cuộn: bọc `<Reveal>` (`@/shared/components/Reveal`).
- Trạng thái loading: `<Loader2 className="size-4 animate-spin" />` + chữ mô tả tiếng Việt.
- Thông báo lỗi trong form: `rounded-xl bg-destructive/10 px-3 py-2 text-sm text-destructive`; thành công: nền emerald nhạt, chữ emerald.
- Ngôn ngữ giao diện: **tiếng Việt** (label, placeholder, thông báo lỗi). Giữ giọng văn hiện có.

### 4.6. Dropdown chọn giá trị — luôn dùng `SelectField`

- **Không dùng thẻ `<select>` gốc** (danh sách `<option>` do hệ điều hành vẽ, không đồng bộ giao diện). Dùng `SelectField` (`@/shared/components/SelectField`), bọc shadcn `Select` (`@/components/ui/select`, chạy trên `@base-ui/react`).
- Props chính: `options` (`[{ value, label }]`), `value`, `onValueChange(value)` (nhận lại đúng `value` gốc, số hay chuỗi đều được), `placeholder`, `id` (cho `<label htmlFor>`), `aria-label`, `aria-invalid`.
- `variant="pill"` (mặc định): thanh lọc, bo tròn hẳn. `variant="field"`: ô trong form, bo `rounded-xl` cùng dáng ô input. Truyền `className` để đổi chiều cao (vd `h-10`); `active` tô nhẹ nút khi đang lọc khác mặc định.
- Popup bo `rounded-2xl`, xổ ngay dưới nút, mục đang chọn tô `bg-brand-soft` (không có dấu tick).
- Trong form react-hook-form phải bọc bằng `Controller` (không dùng `register`): `onValueChange={field.onChange}`, `onBlur={field.onBlur}`.
- Giá trị rỗng/`undefined` của option (vd "Tất cả danh mục") được coi là một lựa chọn hợp lệ; giá trị không khớp option nào thì hiện `placeholder`.

---

## 5. Quy ước code

### 5.1. Gọi API

- **Chỉ dùng `apiClient`** (`@/shared/api/apiClient`):
  - `baseURL = VITE_VEGGIEPAL_API_BASE_URL` (đi qua API gateway).
  - Request interceptor tự gắn `Authorization: Bearer <token>` (token ở `localStorage` key `token`) — **không tự thêm header token**.
  - **`validateStatus: () => true`** → axios **không throw** khi 4xx/5xx. **Bắt buộc tự kiểm tra `res.status >= 400`** rồi `throw new Error(res.data?.message || "<thông báo mặc định tiếng Việt>")`.
- Response envelope của server: `{ code, message, result }`. Dữ liệu thật nằm ở `res.data.result`. Thành công `code = 1000`.
- Mẫu chuẩn (xem `features/profile/api/profileApi.js`):
  ```js
  function unwrap(res, fallbackMessage) {
    if (res.status >= 400) throw new Error(res.data?.message || fallbackMessage);
    return res.data?.result;
  }
  export async function getProfile() {
    const res = await apiClient.get("/users/me");
    return unwrap(res, "Không lấy được thông tin hồ sơ");
  }
  ```
- Hàm API chỉ gọi + chuẩn hóa dữ liệu, **không** chứa state/UI. Đường dẫn bỏ tiền tố `/api` (đã nằm trong baseURL).
- Upload file: `FormData`, field `file`, header `multipart/form-data`.

### 5.2. Server state (React Query)

- Dữ liệu từ API thật → `useQuery` / `useMutation` trong `features/<x>/hooks/`.
- Khóa cache khai báo tập trung ở `features/<x>/queryKeys.js`, dạng mảng phân cấp (`["nutrition", "health-records", "latest"]`).
- `queryClient` (`@/lib/queryClient`) mặc định: `retry: false`, `refetchOnWindowFocus: false`. Không đổi cấu hình này.
- Sau mutation: `queryClient.setQueryData` hoặc `invalidateQueries` theo mẫu `useProfile.js`.
- Hook trả về dạng gọn: `{ data/profile, loading, error }` với `error` là string tiếng Việt.

### 5.3. Client state (Zustand)

- Store dùng `create` từ `zustand`. Hiện có: `useAuthStore` (`features/auth/store/authStore.js`) và `useThemeStore` (`shared/store/themeStore.js`).
- Dùng selector: `useAuthStore((s) => s.user)`, `useAuthStore(selectIsAuthenticated)`.
- Auth: `token` và `user` lưu song song `localStorage` (key `token`, `user`). `logout()` phải `queryClient.clear()`.
- **Không** nhét dữ liệu server vào Zustand (để React Query lo).

### 5.4. Form

- `useForm({ resolver: zodResolver(schema), defaultValues })` + `register`.
- Schema zod đặt trong `schema.js` (`features/<x>/schema.js` hoặc `src/lib/schema.js`); thông báo lỗi **tiếng Việt**.
- Lỗi từ server: `setError("root", { message })` rồi hiển thị `errors.root.message`.
- Trạng thái nút submit dùng `formState.isSubmitting`; invalid hiển thị qua `aria-invalid={Boolean(errors.x)}`.
- Label gắn input bằng `htmlFor` + `useId()` (hoặc bọc `<label>`); thêm `autoComplete` phù hợp.

### 5.5. Routing & bảo vệ route

- Khai báo route ở `src/app/routes.jsx`. Route cần đăng nhập → `<ProtectedRoute>` (đá về `/login`, nhớ `state.from`).
- Điều hướng: `Link`, `useNavigate` từ `react-router-dom`. Route lạ → `Navigate to="/"`.

### 5.6. Style & component

- Chỉ viết class Tailwind trực tiếp trong JSX; gộp/điều kiện bằng `cn(...)` từ `@/lib/utils`.
- Class dùng lặp lại trong 1 file → gom thành hằng (`const fieldClass = "..."`) như code hiện tại.
- CSS tùy chỉnh (keyframes, autofill...) chỉ thêm vào `src/styles/globals.css`, đúng `@layer`.
- Component ở `components/ui/` là shadcn — file component chỉ export component; `cva` variants tách sang `*-variants.js` (để Fast Refresh hoạt động, ESLint `react-refresh` bắt lỗi này).
- Không dùng file ảnh/SVG làm icon hay minh hoạ: dùng `lucide-react`. Logo là `Logo` / `LogoMark` (`@/shared/components/Logo`, vẽ lại logo app mobile bằng SVG inline); favicon là `public/favicon.svg`. Video (nền trang chủ) đặt trong `src/assets/video/` và `import` vào component.
- Comment trong code viết bằng **tiếng Việt**, ngắn, giải thích "vì sao" (theo phong cách hiện có).

### 5.7. Test (test tạm — viết để kiểm tra, xong thì xóa)

- Repo **không giữ file test lâu dài**. Khi cần kiểm tra logic (có lỗi logic, code/flow mới), cứ viết `xxx.test.js` để test, **test xong và mọi thứ ổn thì xóa file test đi** cho repo gọn.
- Dùng `node:test` + `node:assert/strict`, đặt `xxx.test.js` cạnh file thuần JS cần test (utils, logic không phụ thuộc React/DOM).
- Chạy: `npm test`. Không viết test cần DOM/JSX nếu không cài thêm công cụ — hãy tách logic ra hàm thuần để test.
- UI thì không viết test: người dùng tự kiểm tra, có lỗi UI thì báo lại để cùng sửa.

### 5.8. Lint

- `npm run lint` phải sạch trước khi báo xong. Cấu hình: ESLint flat (`eslint.config.js`) với `js.recommended`, `react-hooks`, `react-refresh/vite`.

---

## 6. Thêm shadcn component (nếu thực sự cần)

Cấu hình trong `components.json`: style `base-nova`, `tsx: false`, `baseColor: neutral`, `cssVariables: true`, icon `lucide`, CSS tại `src/styles/globals.css`.
Aliases: `components → @/components`, `ui → @/components/ui`, `lib → @/lib`, `utils → @/lib/utils`, `hooks → @/hooks`.

```bash
npx shadcn@latest add <component>
```

Sau khi thêm: kiểm tra component dùng đúng token màu của VeggiePal (mục 4), bo `rounded-full` cho nút theo quy ước, và hiển thị ổn ở dark mode.

---

## 7. Checklist trước khi báo hoàn thành

- [ ] Không thêm dependency mới (hoặc đã được người dùng cho phép).
- [ ] File mới là `.js/.jsx`, đặt đúng thư mục feature, import bằng `@/`.
- [ ] Màu/font/bo góc dùng token, khớp UI hiện có; kiểm tra cả **light và dark**.
- [ ] Nút dùng `<Button>`; icon dùng `lucide-react`.
- [ ] API đi qua `apiClient`, tự check `status >= 400`, thông báo lỗi tiếng Việt.
- [ ] Dữ liệu server dùng React Query; state toàn cục dùng Zustand; form dùng RHF + zod.
- [ ] Responsive (mobile → desktop) và có trạng thái loading/lỗi.
- [ ] `npm run lint` chạy sạch. Nếu có viết test tạm thì `npm test` phải pass, rồi **xóa file `*.test.js` đã viết**.
- [ ] **Cập nhật tài liệu**: có code mới / flow mới / thay đổi cấu trúc, route, API, env, lệnh... thì cập nhật lại `docs/TECH_STACK.md` và `README.md` cho khớp.
