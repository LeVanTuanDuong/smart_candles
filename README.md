# 🕯️ Smart Candles - Nến Thông Minh

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Bluetooth](https://img.shields.io/badge/Bluetooth-0082FC?logo=bluetooth&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)

**Ứng dụng điều khiển nến thông minh kết hợp với AI chatbot tâm lý học để chăm sóc sức khỏe tinh thần**

[Features](#-tính-năng) • [Screenshots](#-giao-diện) • [Technology](#-công-nghệ) • [Architecture](#-kiến-trúc)

</div>

---

## 📱 Giới thiệu

**Smart Candles** là ứng dụng di động thông minh kết hợp điều khiển nến thông minh qua Bluetooth với AI chatbot tâm lý học để tạo ra trải nghiệm chăm sóc sức khỏe tinh thần toàn diện. Ứng dụng giúp người dùng:

- 🎯 **Theo dõi và cảnh báo nhiệt độ** nến để đảm bảo an toàn
- 💡 **Điều khiển đèn LED** với nhiều chế độ màu sắc và độ sáng
- 🎵 **Phát nhạc thiền định** và âm thanh thiên nhiên
- 🌸 **Gợi ý tinh dầu** phù hợp với tâm trạng
- 🤖 **Chatbot AI** phân tích tâm trạng và đưa ra gợi ý cá nhân hóa
- 📔 **Nhật ký tâm trạng** để theo dõi cảm xúc hàng ngày

---

## ✨ Tính năng

### 🔥 Điều khiển Nến Thông Minh

- **Kết nối Bluetooth**: Kết nối không dây với thiết bị ESP32 để điều khiển nến
- **Theo dõi nhiệt độ**: Giám sát nhiệt độ nến theo thời gian thực
- **Cảnh báo an toàn**:
  - 🟢 **An toàn** (< 40°C): LED xanh
  - 🟡 **Cảnh báo** (40-50°C): LED vàng, thông báo
  - 🔴 **Nguy hiểm** (> 50°C): LED đỏ, cảnh báo khẩn cấp
- **Lịch sử nhiệt độ**: Xem lịch sử nhiệt độ và trạng thái an toàn theo thời gian

### 💡 Điều khiển Đèn LED

- **3 chế độ màu sắc**:
  - 🌅 **Warm White**: Ánh sáng ấm, thư giãn
  - 🟠 **Amber**: Hỗ trợ giấc ngủ
  - 🔵 **Soft Blue**: Bình tĩnh, thiền định
- **Điều chỉnh độ sáng**: Thanh trượt từ 0-100%
- **Bật/Tắt đèn**: Điều khiển nhanh qua ứng dụng
- **Tự động hóa**: Tự động bật đèn theo gợi ý của chatbot

### 🎵 Thư viện Nhạc & Phát nhạc

- **Thư viện nhạc đa dạng**:
  - 🎹 Nhạc Piano chậm
  - 🌊 Ambient
  - 🌿 Âm thanh thiên nhiên (mưa, đại dương)
  - 🧘 Nhạc thiền định
- **Điều khiển phát nhạc**:
  - Phát/Dừng
  - Chuyển bài trước/sau
  - Điều chỉnh âm lượng mượt mà
  - Hiển thị tiến trình phát
- **Tải lên nhạc**: Người dùng có thể tải lên file nhạc từ thiết bị
- **Gợi ý nhạc thông minh**: Chatbot gợi ý nhạc phù hợp với tâm trạng
- **Hướng dẫn thiền**: Màn hình thiền định với nhạc và gợi ý bài tập

### 🌸 Thư viện Tinh dầu

- **12 loại tinh dầu phổ biến**:
  - 🌺 Oải Hương (Lavender)
  - 🪵 Hương Trầm (Sandalwood)
  - 🌿 Bạc Hà (Peppermint)
  - 🌲 Khuynh Diệp (Eucalyptus)
  - 🍃 Tràm Trà (Tea Tree)
  - 🍊 Bưởi (Grapefruit)
  - 🍋 Hương Cam (Orange)
  - 🌱 Sả Chanh (Lemongrass)
  - 🫚 Gừng (Ginger)
  - 🌼 Ngọc Lan Tây (Ylang-Ylang)
  - 🌸 Hoa Nhài (Jasmine)
  - 🍋 Chanh (Lemon)
- **Chi tiết tinh dầu**: Mô tả và đặc điểm nổi bật cho từng loại
- **Hướng dẫn sử dụng**: 4 cách sử dụng tinh dầu và lưu ý an toàn
- **Thêm tinh dầu**: Người dùng có thể thêm tinh dầu của mình với hình ảnh và mô tả
- **Gợi ý thông minh**: Chatbot gợi ý tinh dầu dựa trên tâm trạng

### 🤖 Chatbot AI Tâm lý học

- **Phân tích tâm trạng đa chiều**:
  - 📊 Phân tích từ khóa cảm xúc với trọng số
  - 🎯 Xác định cường độ cảm xúc (0-10)
  - 🧠 Phân loại đa cảm xúc (ví dụ: 55% buồn, 30% lo âu, 15% mệt)
  - 📈 Tính điểm mức độ nghiêm trọng (ESS 0-100)
  - ⏰ Nhận biết ngữ cảnh (thời gian, lịch sử gần đây)
- **5 loại tâm trạng chính**:

  - 😰 **Căng thẳng / Lo âu**
  - 😢 **Buồn / Trầm cảm**
  - 😴 **Mệt mỏi**
  - 🌙 **Khó ngủ**
  - 😊 **Bình thường / Tích cực**

- **Gợi ý tự động**:

  - 🎵 Nhạc phù hợp với tâm trạng
  - 🌸 Tinh dầu được khuyên dùng
  - 💡 Màu đèn và độ sáng tối ưu
  - ✅ Tự động áp dụng khi người dùng đồng ý

- **Tương tác tự nhiên**:
  - 💬 Phản hồi đồng cảm, không phán xét
  - 🎨 Tránh lặp lại, câu trả lời đa dạng
  - 🎯 Câu hỏi theo dõi thông minh
  - ⚠️ Cảnh báo an toàn cho tình huống nguy hiểm

### 📔 Nhật ký Tâm trạng

- **Lịch tương tác**: Xem và ghi lại tâm trạng theo ngày
- **Chọn tâm trạng**: 5 loại tâm trạng với emoji
- **Ghi chú**: Viết nhật ký chi tiết về cảm xúc
- **Lưu trữ**: Dữ liệu được lưu vĩnh viễn đến khi xóa app
- **Hiển thị trực quan**: Emoji che số ngày đã có nhật ký

### 👤 Quản lý Hồ sơ

- **Thông tin cá nhân**:
  - Ảnh đại diện
  - Tên, email
  - Cập nhật và lưu vào Firebase
- **Lịch sử sử dụng**: Theo dõi các hoạt động trong app

- **Sở thích**: Lưu các tinh dầu và nhạc yêu thích

- **Thống kê**:

  - Tần suất sử dụng
  - Tâm trạng phổ biến
  - Thời gian sử dụng

- **Trợ giúp & Hỗ trợ**:

  - Gửi email hỗ trợ
  - Câu hỏi thường gặp
  - Hướng dẫn sử dụng

- **Về ứng dụng**: Thông tin phiên bản và giấy phép

### ⚙️ Cài đặt

- **Kết nối**:
  - Bật/Tắt Bluetooth
  - Trạng thái kết nối ESP32
- **Đèn ban đêm**:
  - Bật/Tắt đèn
  - Điều chỉnh độ sáng
  - Chọn màu sáng
- **Nhạc**:
  - Bật/Tắt phát nhạc
  - Điều chỉnh âm lượng
- **An toàn**:
  - Ngưỡng cảnh báo nhiệt độ (40-60°C)
  - Bật/Tắt thông báo
- **Tự động hóa**:
  - Tự động bật đèn
  - Tự động phát nhạc
- **Thông tin**:
  - Phiên bản ứng dụng
  - Trợ giúp
  - Chính sách bảo mật

### 🔐 Xác thực Người dùng

- **Đăng nhập/Đăng ký** với email và mật khẩu
- **Đăng nhập Google** một cú nhấp
- **Firebase Authentication** để bảo mật dữ liệu
- **Lưu trữ đám mây** với Cloud Firestore

---

## 🎨 Giao diện

### Trang chủ

- 📊 **Card nhiệt độ**: Hiển thị nhiệt độ và trạng thái an toàn với màu sắc trực quan
- 💬 **Chatbot Section**: Nút tâm trạng nhanh và gợi ý chatbot
- 🎵 **Điều khiển nhạc**: Phát/dừng, chuyển bài, điều chỉnh âm lượng
- 🌸 **Gợi ý tinh dầu**: Card hiển thị tinh dầu được gợi ý với hình ảnh
- 🎶 **Gợi ý nhạc**: Card gợi ý bài nhạc phù hợp
- ⌚ **Dữ liệu Smartwatch**: Hiển thị nhịp tim và nhiệt độ cơ thể (nếu có)

### Chatbot

- 💬 **Giao diện chat**: Bong bóng tin nhắn đẹp mắt
- 🎯 **Nút tâm trạng**: Chọn nhanh tâm trạng
- 🎨 **Phản hồi đa dạng**: Tránh lặp lại, câu trả lời tự nhiên
- ⚡ **Gợi ý tự động**: Tự động áp dụng nhạc, đèn, tinh dầu

### Nhật ký Tâm trạng

- 📅 **Lịch tương tác**: Chọn ngày và ghi lại tâm trạng
- 😊 **Emoji tâm trạng**: 5 loại tâm trạng với emoji
- 📝 **Ghi chú**: Viết nhật ký chi tiết
- 💾 **Lưu trữ**: Dữ liệu được lưu vĩnh viễn

### Thư viện

- 🎵 **Thư viện nhạc**: Xem và phát nhạc từ thư viện
- 🌸 **Thư viện tinh dầu**: Xem chi tiết và thêm tinh dầu
- 📤 **Tải lên**: Tải lên nhạc và hình ảnh từ thiết bị

---

## 🛠️ Công nghệ

### Framework & Language

- **Flutter 3.0+**: Framework đa nền tảng
- **Dart 3.0+**: Ngôn ngữ lập trình

### Backend & Authentication

- **Firebase Core**: Nền tảng backend
- **Firebase Authentication**: Xác thực người dùng
- **Cloud Firestore**: Cơ sở dữ liệu NoSQL
- **Firebase Storage**: Lưu trữ file (ảnh, nhạc)
- **Google Sign-In**: Đăng nhập bằng Google

### Bluetooth & Hardware

- **flutter_blue_plus**: Kết nối Bluetooth Low Energy (BLE)
- **ESP32**: Thiết bị phần cứng nến thông minh

### Audio & Media

- **just_audio**: Phát nhạc và điều khiển audio
- **file_picker**: Chọn file nhạc từ thiết bị
- **image_picker**: Chọn ảnh từ camera hoặc thư viện

### Local Storage

- **shared_preferences**: Lưu trữ cài đặt và dữ liệu local
- **path_provider**: Quản lý đường dẫn file

### UI/UX

- **Material Design 3**: Thiết kế Material mới nhất
- **Custom Animations**: Animation mượt mà cho navigation và transitions
- **Gradient Backgrounds**: Nền gradient đẹp mắt
- **Custom Widgets**: Widgets tùy chỉnh cho từng tính năng

### Utilities

- **intl**: Định dạng ngày tháng và quốc tế hóa
- **http**: Giao tiếp HTTP (nếu cần)
- **url_launcher**: Mở email và URL
- **package_info_plus**: Lấy thông tin phiên bản app
- **clipboard**: Sao chép văn bản

---

## 🏗️ Kiến trúc

### Services (Dịch vụ)

- **AuthService**: Quản lý xác thực người dùng
- **BluetoothService**: Kết nối và giao tiếp với ESP32
- **ChatbotService**: Logic chatbot và gợi ý
- **ChatbotFlowService**: Quy trình tương tác chatbot
- **EmotionAnalysisService**: Phân tích cảm xúc chi tiết
- **EssentialOilService**: Quản lý thư viện tinh dầu
- **GlobalMusicPlayerService**: Phát nhạc toàn cục
- **MusicService**: Quản lý thư viện nhạc
- **SettingsService**: Quản lý cài đặt
- **SuggestionService**: Quản lý gợi ý
- **TemperatureHistoryService**: Lịch sử nhiệt độ
- **JournalStorageService**: Lưu trữ nhật ký

### Models (Mô hình dữ liệu)

- **DeviceStatus**: Trạng thái thiết bị (nhiệt độ, đèn, nhạc)
- **MoodType**: Loại tâm trạng
- **MusicTrack**: Thông tin bài nhạc
- **EssentialOil**: Thông tin tinh dầu
- **TemperatureHistoryEntry**: Lịch sử nhiệt độ
- **SmartwatchData**: Dữ liệu smartwatch

### Screens (Màn hình)

- **HomeScreen**: Màn hình chính với navigation
- **DashboardHomeScreen**: Trang chủ với các card tính năng
- **ChatbotScreen**: Giao diện chatbot
- **MoodJournalScreen**: Nhật ký tâm trạng
- **MusicLibraryScreen**: Thư viện nhạc
- **EssentialOilLibraryScreen**: Thư viện tinh dầu
- **MeditationGuideScreen**: Hướng dẫn thiền
- **SafetyHistoryScreen**: Lịch sử an toàn
- **ProfileScreen**: Hồ sơ người dùng
- **SettingsScreen**: Cài đặt
- **LoginScreen/RegisterScreen**: Đăng nhập/Đăng ký

### Widgets (Thành phần UI)

- **CustomBottomNavBar**: Thanh navigation tùy chỉnh với animation
- **TemperatureCardHome**: Card hiển thị nhiệt độ
- **MusicControlHome**: Điều khiển nhạc
- **EssentialOilSuggestionCard**: Card gợi ý tinh dầu
- **MusicSuggestionCard**: Card gợi ý nhạc
- **ChatbotSectionHome**: Section chatbot trên trang chủ
- **SmartwatchCardHome**: Card dữ liệu smartwatch

---

## 🎯 Tính năng nổi bật

### 1. Phân tích Tâm trạng Thông minh

- Hệ thống phân tích đa lớp để hiểu sâu tâm trạng người dùng
- Gợi ý cá nhân hóa dựa trên cảm xúc, thời gian, và lịch sử
- Tự động điều chỉnh nhạc, đèn, và tinh dầu

### 2. An toàn là Ưu tiên

- Giám sát nhiệt độ theo thời gian thực
- Cảnh báo 3 cấp độ (An toàn, Cảnh báo, Nguy hiểm)
- Lịch sử nhiệt độ để theo dõi xu hướng

### 3. Trải nghiệm Người dùng Mượt mà

- Animation mượt mà khi chuyển màn hình
- Giao diện gradient đẹp mắt
- Navigation trượt thay vì nhảy
- Phản hồi tức thì cho mọi tương tác

### 4. Tích hợp Đa nền tảng

- Firebase cho backend và authentication
- Bluetooth cho kết nối phần cứng
- Local storage cho dữ liệu offline
- Cloud storage cho đồng bộ đám mây

---

## 📊 Trạng thái Dự án

- ✅ Kết nối Bluetooth với ESP32
- ✅ Theo dõi và cảnh báo nhiệt độ
- ✅ Điều khiển đèn LED
- ✅ Phát nhạc và quản lý thư viện
- ✅ Thư viện tinh dầu với gợi ý
- ✅ Chatbot AI phân tích tâm trạng
- ✅ Nhật ký tâm trạng
- ✅ Hồ sơ người dùng
- ✅ Cài đặt và tự động hóa
- ✅ Firebase Authentication
- ✅ Giao diện đẹp với animation

---

## 🤝 Đóng góp

Chúng tôi hoan nghênh mọi đóng góp! Vui lòng:

1. Fork dự án
2. Tạo branch cho tính năng mới (`git checkout -b feature/AmazingFeature`)
3. Commit thay đổi (`git commit -m 'Add some AmazingFeature'`)
4. Push lên branch (`git push origin feature/AmazingFeature`)
5. Mở Pull Request

---

## 📄 Giấy phép

Dự án này được phân phối dưới giấy phép MIT. Xem file `LICENSE` để biết thêm thông tin.

---

## 👥 Tác giả

**Smart Candles Team**

- 💡 Phát triển ứng dụng điều khiển nến thông minh
- 🤖 Tích hợp AI chatbot tâm lý học
- 🎨 Thiết kế giao diện người dùng đẹp mắt
- 🔒 Đảm bảo an toàn và bảo mật

---

## 📞 Liên hệ

- 📧 Email hỗ trợ: lephinam260224@gmail.com
- 🐛 Báo lỗi: [Issues](https://github.com/yourusername/smart_candles/issues)
- 💬 Thảo luận: [Discussions](https://github.com/yourusername/smart_candles/discussions)

---

<div align="center">

**Made with ❤️ by Smart Candles Team**

⭐ Nếu bạn thích dự án này, hãy cho chúng tôi một ngôi sao!

</div>
