# Kiến trúc Smart Candles – Feature-based

Tài liệu mô tả cấu trúc theo **tính năng (feature)** để dễ bảo trì và tái sử dụng (copy cả feature sang app khác).

**Trạng thái:** Đã có barrel files (`lib/features/<tên>/<tên>.dart`, `lib/shared/shared.dart`, `lib/core/core.dart`) re-export từ đường dẫn hiện tại. Code thực tế vẫn nằm ở `lib/screens/`, `lib/services/`, `lib/models/`, `lib/widgets/`. Để **di chuyển hẳn** từng feature vào thư mục riêng, làm theo [REFACTOR_GUIDE.md](REFACTOR_GUIDE.md).

---

## 1. Cấu trúc hiện tại (vấn đề)

```
lib/
├── main.dart
├── models/           # Tất cả model chung → khó biết model nào thuộc feature nào
├── screens/          # Tất cả màn hình → phụ thuộc chéo nhiều services/models
├── services/         # Tất cả service → dùng chung, khó tách feature
└── widgets/          # Widget dùng chung → một số gắn chặt 1 feature
```

**Vấn đề:**
- Muốn đưa 1 tính năng (vd: Chatbot) sang app khác → phải mở từng file, tìm đúng model/service/widget liên quan.
- Bảo trì: thay đổi 1 feature dễ ảnh hưởng file của feature khác.
- Ranh giới feature không rõ: không có 1 chỗ “toàn bộ Chatbot nằm ở đây”.

---

## 2. Cấu trúc mới (theo feature)

```
lib/
├── main.dart                 # Chỉ bootstrap app, theme, routes
├── core/                     # Khởi tạo app (theme, splash, lỗi)
│   ├── app.dart
│   ├── theme.dart
│   └── splash/
├── shared/                   # Dùng chung 2+ feature (model, service, widget)
│   ├── models/
│   ├── services/
│   └── widgets/
├── features/
│   ├── auth/
│   │   ├── auth.dart         # Barrel: export public API của feature
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── services/
│   ├── chatbot/
│   ├── dashboard/
│   ├── device/
│   ├── essential_oil/
│   ├── favorites/
│   ├── history/
│   ├── mood_journal/
│   ├── music/
│   └── profile/
└── firebase_options.dart     # Giữ ở root (Flutter generate)
```

**Nguyên tắc:**
- Mỗi **feature** = 1 thư mục, chứa: `presentation/` (screens, widgets), `services/`, `models/` (nếu chỉ feature đó dùng).
- Thứ dùng bởi **≥2 feature** → đặt trong `shared/`.
- Mỗi feature có file **barrel** `feature_name.dart` export toàn bộ API public (screens, services cần expose) để app hoặc feature khác import 1 dòng: `import 'package:smart_candles/features/chatbot/chatbot.dart';`

---

## 3. Bản đồ feature ↔ file (flow chi tiết)

### 3.1. Feature: **auth**
| Thành phần | File |
|------------|------|
| Screens | `auth_gate.dart`, `login_screen.dart`, `register_screen.dart` |
| Services | `auth_service.dart` |
| Models | — |
| Phụ thuộc | Firebase Auth, Firestore; sau login → `HomeScreen` (dashboard) |

**Flow:** Splash → AuthGate → (chưa đăng nhập) LoginScreen / RegisterScreen → (đã đăng nhập) HomeScreen.

---

### 3.2. Feature: **chatbot**
| Thành phần | File |
|------------|------|
| Screens | `chatbot_screen.dart`, `chat_history_screen.dart` |
| Widgets | `chat_bubble.dart`, `chatbot_avatar.dart`, `mood_buttons_chat.dart` |
| Services | `chatbot_service.dart`, `conversation_manager.dart`, `chat_history_service.dart`, `ai_inference_service.dart`, `bert_tokenizer.dart` |
| Models | `message.dart` |
| Phụ thuộc | `mood_type` (shared), gợi ý nhạc/đèn/tinh dầu → gọi callback sang dashboard/music/essential_oil |

**Flow:** User nhập tin → ChatbotService (+ AI) → ConversationManager, ChatHistoryService; có thể chọn mood, xem lịch sử chat.

---

### 3.3. Feature: **dashboard** (Home + Dashboard)
| Thành phần | File |
|------------|------|
| Screens | `home_screen.dart`, `dashboard_home_screen.dart` |
| Widgets | `custom_bottom_nav_bar.dart`, `temperature_card_home.dart`, `chatbot_section_home.dart`, `music_suggestion_card.dart`, `essential_oil_suggestion_card.dart`, `music_control_home.dart`, `smartwatch_card_home.dart`, `suggestion_card_home.dart`, `voice_monitor_widget.dart`, `danger_alert_dialog.dart`, `bluetooth_device_dialog.dart` |
| Services | `suggestion_service.dart` (chia sẻ với chatbot) |
| Models | Dùng từ shared: `device_status`, `mood_type`, `smartwatch_data`, `music_track`, `essential_oil`, `temperature_history_entry` |
| Phụ thuộc | device (Bluetooth, temperature), music, essential_oil, mood_journal, profile, meditation, safety_history |

**Flow:** Home 2 tab (Dashboard / Chatbot). Dashboard: nhiệt độ, gợi ý nhạc/tinh dầu, điều khiển nhạc, smartwatch, voice; mở Profile, Mood Journal, Safety History, Music Library, Meditation.

---

### 3.4. Feature: **device** (Bluetooth, nhiệt độ, thiết bị)
| Thành phần | File |
|------------|------|
| Screens | `device_control_screen.dart`, `safety_history_screen.dart` |
| Widgets | `temperature_status_widget.dart`, `bluetooth_device_dialog.dart` |
| Services | `bluetooth_service.dart`, `temperature_history_service.dart`, `esp_api_service.dart`, `wifi_service.dart` |
| Models | `device_status.dart`, `temperature_history_entry.dart` |
| Phụ thuộc | `shared/settings_service` (ngưỡng nhiệt độ) |

**Flow:** Kết nối BLE → đọc nhiệt độ → lưu TemperatureHistoryService; Safety History xem lịch sử nguy hiểm.

---

### 3.5. Feature: **music**
| Thành phần | File |
|------------|------|
| Screens | `music_library_screen.dart`, `meditation_guide_screen.dart` |
| Widgets | (dùng chung: `music_control_home.dart`, `music_suggestion_card.dart` trong dashboard) |
| Services | `music_service.dart`, `global_music_player_service.dart` |
| Models | `music_track.dart` |
| Phụ thuộc | — |

**Flow:** Thư viện nhạc CRUD, Meditation Guide chọn nhạc; GlobalMusicPlayer phát nhạc toàn app.

---

### 3.6. Feature: **essential_oil**
| Thành phần | File |
|------------|------|
| Screens | `essential_oil_library_screen.dart`, `essential_oil_detail_screen.dart`, `essential_oil_guide_screen.dart` |
| Widgets | `essential_oil_suggestion_card.dart` |
| Services | `essential_oil_service.dart` |
| Models | `essential_oil.dart` |
| Phụ thuộc | — |

**Flow:** Thư viện tinh dầu CRUD, xem chi tiết, hướng dẫn; chatbot gợi ý tinh dầu qua SuggestionService.

---

### 3.7. Feature: **mood_journal**
| Thành phần | File |
|------------|------|
| Screens | `mood_journal_screen.dart` |
| Services | `journal_storage_service.dart` |
| Models | `mood_journal_entry.dart` |
| Phụ thuộc | `mood_type` (shared) |

**Flow:** Ghi nhận mood theo ngày, lưu qua JournalStorageService.

---

### 3.8. Feature: **profile**
| Thành phần | File |
|------------|------|
| Screens | `profile_screen.dart`, `settings_screen.dart`, `personal_info_screen.dart`, `about_screen.dart`, `help_support_screen.dart` |
| Services | Dùng `auth_service`, `settings_service`, `bluetooth_service` (shared/device) |
| Models | Dùng `device_status` (shared) |
| Phụ thuộc | auth, device, history, favorites, music, essential_oil |

**Flow:** Profile → Settings, Personal info, Usage history, Favorites, Statistics, Help, About.

---

### 3.9. Feature: **favorites**
| Thành phần | File |
|------------|------|
| Screens | `favorites_screen.dart` |
| Services | Dùng `essential_oil_service`, `music_service` |
| Models | Dùng `essential_oil`, `music_track` |
| Phụ thuộc | essential_oil, music |

**Flow:** Hiển thị danh sách yêu thích (tinh dầu + nhạc), mở chi tiết từng feature.

---

### 3.10. Feature: **history**
| Thành phần | File |
|------------|------|
| Screens | `usage_history_screen.dart`, `statistics_screen.dart` |
| Services | Dùng `journal_storage_service`, `temperature_history_service` |
| Models | Dùng `mood_journal_entry`, `temperature_history_entry`, `device_status` |
| Phụ thuộc | mood_journal, device |

**Flow:** Usage: tổng hợp nhật ký mood + nhiệt độ; Statistics: thống kê.

---

## 4. Shared (dùng chung)

| Thành phần | File | Dùng bởi |
|------------|------|----------|
| Models | `mood_type.dart`, `suggestion.dart` | chatbot, dashboard, mood_journal, suggestion_service |
| Models | `device_status.dart`, `smartwatch_data.dart` | dashboard, device, profile, history |
| Services | `settings_service.dart` | dashboard, device, profile |
| Services | `bluetooth_service.dart` | dashboard, device, profile (shared vì nhiều feature dùng) |
| Widgets | `danger_alert_dialog.dart` | dashboard (có thể để trong dashboard nếu chỉ 1 nơi dùng) |

---

## 5. Cách đưa 1 feature sang app khác

1. **Copy nguyên thư mục feature** (vd: `lib/features/chatbot/`).
2. **Copy các phần shared mà feature đó import** (xem import trong feature), ví dụ: `mood_type`, `message`, v.v.
3. **Copy dependencies pubspec** (Firebase, tflite, http, … theo từng feature).
4. **Trong app mới:**  
   - Đăng ký route / màn hình tương ứng.  
   - Inject hoặc khởi tạo service (nếu cần) và import barrel:  
     `import 'package:smart_candles/features/chatbot/chatbot.dart';`

---

## 6. Cách bảo trì

- **Sửa 1 tính năng:** Chỉ sửa trong `lib/features/<tên_feature>/` và `lib/shared/` (nếu đụng tới shared).
- **Thêm tính năng mới:** Tạo `lib/features/<tên_mới>/` với cấu trúc giống các feature hiện có, thêm barrel export, rồi đăng ký trong app (main/routes).
- **Tách feature ra package:** Có thể chuyển `features/chatbot` thành package riêng (vd. `package:app_chatbot`) và depend trong `pubspec.yaml`.

---

## 7. Tóm tắt thư mục feature

| Feature        | Thư mục           | Barrel file   |
|----------------|-------------------|---------------|
| Auth           | `features/auth/`  | `auth.dart`   |
| Chatbot        | `features/chatbot/` | `chatbot.dart` |
| Dashboard (Home) | `features/dashboard/` | `dashboard.dart` |
| Device         | `features/device/`  | `device.dart`   |
| Essential oil  | `features/essential_oil/` | `essential_oil.dart` |
| Favorites      | `features/favorites/` | `favorites.dart` |
| History        | `features/history/`  | `history.dart`   |
| Mood journal   | `features/mood_journal/` | `mood_journal.dart` |
| Music          | `features/music/`   | `music.dart`   |
| Profile        | `features/profile/` | `profile.dart` |

Mọi import giữa feature với feature hoặc với shared nên dùng **package import** (ví dụ `package:smart_candles/shared/...`) để sau này dễ tách package.
