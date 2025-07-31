# Store Manager

Ứng dụng quản lý cửa hàng hiện đại được xây dựng bằng Flutter, tích hợp với WooCommerce API để quản lý sản phẩm một cách hiệu quả.

## 🚀 Tính năng chính

### 📱 Giao diện người dùng
- **Giao diện hiện đại**: Thiết kế Material Design 3 với theme tùy chỉnh
- **Responsive**: Tương thích với nhiều kích thước màn hình
- **Dark/Light mode**: Hỗ trợ chế độ sáng/tối
- **Navigation**: Điều hướng mượt mà với Go Router

### 🛍️ Quản lý sản phẩm
- **Danh sách sản phẩm**: Hiển thị sản phẩm dạng grid với hình ảnh
- **Chi tiết sản phẩm**: Xem và chỉnh sửa thông tin chi tiết
- **Thêm sản phẩm mới**: Form tạo sản phẩm với validation
- **Gallery**: Quản lý hình ảnh sản phẩm
- **Tìm kiếm và lọc**: Tìm kiếm sản phẩm nhanh chóng

### 🔐 Xác thực và bảo mật
- **Đăng nhập**: Hệ thống xác thực an toàn
- **Lưu trữ bảo mật**: Sử dụng Flutter Secure Storage
- **Quản lý phiên**: Tự động đăng xuất khi hết hạn

### 📊 Báo cáo và thống kê
- **Biểu đồ**: Hiển thị dữ liệu với FL Chart
- **Thống kê**: Báo cáo doanh thu và sản phẩm
- **Dashboard**: Tổng quan tình hình kinh doanh

## 🏗️ Cấu trúc dự án

```
lib/
├── models/              # Data models
│   └── product.dart    # Product model với WooCommerce API
├── services/           # API services
│   ├── product_service.dart    # WooCommerce API integration
│   └── image_service.dart     # Image handling
├── providers/          # State management
│   ├── auth_provider.dart     # Authentication state
│   └── product_provider.dart  # Product state management
├── screens/            # UI screens
│   ├── home_screen.dart       # Dashboard chính
│   ├── login_screen.dart      # Màn hình đăng nhập
│   ├── product_list_screen.dart   # Danh sách sản phẩm
│   ├── product_detail.dart    # Chi tiết sản phẩm
│   ├── new_product_screen.dart    # Thêm sản phẩm mới
│   ├── gallery_screen.dart    # Quản lý hình ảnh
│   ├── order_list_screen.dart # Danh sách đơn hàng
│   └── setting_screen.dart    # Cài đặt ứng dụng
├── widgets/            # Reusable widgets
│   └── shell_widget.dart      # Layout wrapper
└── routers/           # Navigation
    └── app_router.dart        # Route configuration
```

## 🔌 API Integration

### WooCommerce API
Ứng dụng tích hợp hoàn toàn với WooCommerce REST API:

- **Base URL**: `https://kochamtoys.pl/wp-json/wc/v3/`
- **Authentication**: Basic Auth với Consumer Key/Secret
- **Endpoints**:
  - `GET /products` - Lấy danh sách sản phẩm
  - `GET /products/{id}` - Chi tiết sản phẩm
  - `PUT /products/{id}` - Cập nhật sản phẩm
  - `POST /products` - Tạo sản phẩm mới

### Cấu trúc dữ liệu sản phẩm
```dart
class Product {
  final int id;
  final String name;
  final String description;
  final List<MetaData> metaData;  // PACZKA, Karton, Kho hàng
  final List<ProductImage> images;
}
```

## 🛠️ Cài đặt và chạy

### Yêu cầu hệ thống
- Flutter SDK: ^3.8.1
- Dart SDK: ^3.8.1
- Android Studio / VS Code
- Git

### Bước 1: Clone dự án
```bash
git clone <repository-url>
cd store_manager
```

### Bước 2: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 3: Cấu hình API
Tạo file `.env` trong thư mục gốc:
```env
WOOCOMMERCE_CONSUMER_KEY=your_consumer_key
WOOCOMMERCE_CONSUMER_SECRET=your_consumer_secret
WOOCOMMERCE_BASE_URL=https://kochamtoys.pl/wp-json/wc/v3
```

### Bước 4: Chạy ứng dụng
```bash
# Chạy trên thiết bị được kết nối
flutter run

# Chạy trên Android
flutter run -d android

# Chạy trên iOS
flutter run -d ios
```

## 📦 Dependencies

### Core Dependencies
- **flutter**: Framework chính
- **go_router**: ^16.0.0 - Định tuyến ứng dụng
- **provider**: ^6.1.5 - State management
- **http**: ^1.4.0 - HTTP client cho API calls

### UI & UX
- **google_fonts**: ^6.2.1 - Typography
- **fl_chart**: ^1.0.0 - Biểu đồ và thống kê
- **flutter_staggered_grid_view**: ^0.7.0 - Layout grid
- **cached_network_image**: ^3.4.1 - Cache hình ảnh

### Security & Storage
- **flutter_secure_storage**: ^9.2.4 - Lưu trữ bảo mật
- **dio**: ^5.8.0+1 - HTTP client nâng cao

### Media
- **image_picker**: ^1.1.2 - Chọn hình ảnh từ gallery/camera

## 🎨 Theme và Design

Ứng dụng sử dụng Material Design 3 với:
- **Primary Color**: `#00BABA` (Teal)
- **Typography**: Google Fonts Roboto
- **Icons**: Material Icons
- **Layout**: Responsive design

## 🔧 Development

### Cấu trúc Provider Pattern
```dart
// AuthProvider - Quản lý trạng thái đăng nhập
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  
  // Methods: login(), logout(), checkAuth()
}

// ProductProvider - Quản lý dữ liệu sản phẩm
class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  
  // Methods: loadProducts(), updateProduct(), addProduct()
}
```

### Error Handling
- Network error handling
- API response validation
- User-friendly error messages
- Retry mechanisms

## 📱 Screenshots

### Màn hình chính
- Dashboard với thống kê
- Danh sách sản phẩm dạng grid
- Navigation drawer

### Quản lý sản phẩm
- Form thêm/sửa sản phẩm
- Gallery hình ảnh
- Chi tiết sản phẩm

## 🚀 Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork dự án
2. Tạo feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📄 License

Dự án này được phát hành dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.

## 📞 Support

Nếu bạn gặp vấn đề hoặc có câu hỏi, vui lòng:
- Tạo issue trên GitHub
- Liên hệ qua email: [your-email@example.com]
- Tham gia Discord community

---

**Store Manager** - Giải pháp quản lý cửa hàng hiện đại cho doanh nghiệp Việt Nam 🇻🇳
