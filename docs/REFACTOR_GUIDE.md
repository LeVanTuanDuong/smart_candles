# Hướng dẫn Refactor – Di chuyển file vào từng feature

Hiện tại đã có **barrel files** (`lib/features/<tên>/<tên>.dart`) export từ đường dẫn cũ. App vẫn chạy bình thường, chỉ cần import `package:smart_candles/features/auth/auth.dart` là dùng được Auth.

Khi muốn **tách hẳn từng feature sang thư mục riêng** (để copy cả folder sang app khác), làm lần lượt từng feature theo các bước dưới.

---

## Chuẩn bị

- Mỗi feature có cấu trúc:
  ```
  lib/features/<feature>/
  ├── <feature>.dart          # Barrel export (sửa lại export path sau khi move)
  ├── presentation/
  │   ├── screens/
  │   └── widgets/
  ├── services/               # (nếu có)
  └── models/                 # (nếu có, chỉ dùng trong feature)
  ```

- File **dùng chung 2+ feature** giữ trong `lib/shared/` (models, services, widgets). Khi move shared, tạo `lib/shared/models/`, `lib/shared/services/`, `lib/shared/widgets/` và cập nhật mọi import sang `package:smart_candles/shared/...`.

---

## Ví dụ: Di chuyển feature Auth

### Bước 1: Tạo thư mục

```
lib/features/auth/
├── auth.dart
├── presentation/screens/
└── services/
```

### Bước 2: Di chuyển file

| Từ (hiện tại) | Đến |
|---------------|-----|
| `lib/screens/auth_gate.dart` | `lib/features/auth/presentation/screens/auth_gate.dart` |
| `lib/screens/login_screen.dart` | `lib/features/auth/presentation/screens/login_screen.dart` |
| `lib/screens/register_screen.dart` | `lib/features/auth/presentation/screens/register_screen.dart` |
| `lib/services/auth_service.dart` | `lib/features/auth/services/auth_service.dart` |

### Bước 3: Sửa import trong file vừa move

- Trong `auth_gate.dart`:  
  `import 'package:smart_candles/screens/home_screen.dart'`  
  → Giữ nguyên (home_screen vẫn ở lib/screens) hoặc sau khi move dashboard thì dùng  
  `import 'package:smart_candles/features/dashboard/dashboard.dart'`.

- Trong `auth_gate.dart`:  
  `import 'package:smart_candles/screens/login_screen.dart'`  
  → `import 'package:smart_candles/features/auth/presentation/screens/login_screen.dart'`  
  hoặc dùng relative: `import 'login_screen.dart';` (cùng thư mục).

- Trong `login_screen.dart`, `register_screen.dart`: đổi import sang `auth_service` từ  
  `package:smart_candles/features/auth/services/auth_service.dart`.

### Bước 4: Cập nhật barrel `lib/features/auth/auth.dart`

```dart
library;

export 'package:smart_candles/features/auth/services/auth_service.dart';
export 'package:smart_candles/features/auth/presentation/screens/auth_gate.dart';
export 'package:smart_candles/features/auth/presentation/screens/login_screen.dart';
export 'package:smart_candles/features/auth/presentation/screens/register_screen.dart';
```

### Bước 5: Cập nhật mọi file khác đang import auth

- `lib/main.dart` (nếu dùng AuthGate): có thể đổi thành  
  `import 'package:smart_candles/features/auth/auth.dart';`
- `lib/screens/splash_screen.dart`: đổi import AuthService sang  
  `package:smart_candles/features/auth/auth.dart` hoặc path trực tiếp tới `auth_service.dart`.
- `lib/screens/register_screen.dart`: đã nằm trong feature auth, chỉ cần sửa relative/package.
- Các screen khác import `login_screen.dart`, `auth_service.dart`: đổi sang  
  `package:smart_candles/features/auth/auth.dart` (hoặc path cụ thể).

### Bước 6: Xóa file cũ

Sau khi chắc chắn không còn reference tới đường dẫn cũ, xóa:
- `lib/screens/auth_gate.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/register_screen.dart`
- `lib/services/auth_service.dart`

### Bước 7: Chạy lại app

```bash
flutter pub get
flutter run
```

Kiểm tra: đăng nhập, đăng ký, AuthGate, splash.

---

## Thứ tự nên refactor (tránh phụ thuộc ngược)

1. **shared** – Move `lib/models/` (một phần), `lib/services/settings_service.dart`, `bluetooth_service.dart` vào `lib/shared/`, cập nhật toàn bộ import.
2. **auth** – Theo ví dụ trên.
3. **device** – Move models (temperature_history_entry), services (bluetooth, temperature_history, esp_api, wifi), screens, widgets.
4. **music** – Move models (music_track), services, screens, widgets.
5. **essential_oil** – Tương tự.
6. **mood_journal** – Tương tự.
7. **chatbot** – Phụ thuộc mood_type (shared), AI services.
8. **dashboard** – Phụ thuộc nhiều feature; move sau cùng.
9. **profile**, **favorites**, **history** – Move screens (services đã nằm trong feature khác hoặc shared).

---

## Khi đưa feature sang app khác

1. Copy nguyên thư mục `lib/features/<tên>/` (ví dụ `chatbot`).
2. Copy thêm các file trong `lib/shared/` mà feature đó import (xem trong từng file .dart).
3. Copy các dependency trong `pubspec.yaml` cần cho feature đó (Firebase, http, tflite, …).
4. Trong app mới: đăng ký route/màn hình, import barrel:  
   `import 'package:smart_candles/features/chatbot/chatbot.dart';`  
   (hoặc đổi package name nếu copy sang package khác).

Như vậy mỗi feature có ranh giới rõ, dễ bảo trì và tái sử dụng.
