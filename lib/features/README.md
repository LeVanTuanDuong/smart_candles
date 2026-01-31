# Features – Cấu trúc theo tính năng

Mỗi thư mục là **một feature** độc lập. Dùng barrel file `<tên>.dart` để import cả feature:

```dart
import 'package:smart_candles/features/auth/auth.dart';
import 'package:smart_candles/features/chatbot/chatbot.dart';
```

## Danh sách feature

| Feature | Barrel | Mô tả |
|---------|--------|--------|
| **auth** | `auth.dart` | Đăng nhập, đăng ký, AuthGate |
| **chatbot** | `chatbot.dart` | Chat, lịch sử chat, AI |
| **dashboard** | `dashboard.dart` | Home, Dashboard, gợi ý |
| **device** | `device.dart` | Bluetooth, nhiệt độ, safety history |
| **essential_oil** | `essential_oil.dart` | Thư viện tinh dầu, chi tiết, hướng dẫn |
| **favorites** | `favorites.dart` | Danh sách yêu thích (nhạc + tinh dầu) |
| **history** | `history.dart` | Lịch sử sử dụng, thống kê |
| **mood_journal** | `mood_journal.dart` | Nhật ký cảm xúc |
| **music** | `music.dart` | Thư viện nhạc, meditation, player |
| **profile** | `profile.dart` | Profile, cài đặt, about, help |

## Đưa feature sang app khác

1. Copy thư mục `lib/features/<tên>/`.
2. Copy các file trong `lib/shared/` mà feature import (xem trong từng file).
3. Thêm dependency cần thiết vào `pubspec.yaml` của app mới.
4. Import barrel: `import 'package:smart_candles/features/<tên>/<tên>.dart';`

Chi tiết: xem `docs/ARCHITECTURE.md` và `docs/REFACTOR_GUIDE.md`.
