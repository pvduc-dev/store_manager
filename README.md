# Store Manager

Ứng dụng quản lý cửa hàng được xây dựng bằng Flutter.

## Tính năng

- **Quản lý sản phẩm**: Xem danh sách, chi tiết và chỉnh sửa sản phẩm
- **Tích hợp API**: Kết nối với WooCommerce API để đồng bộ dữ liệu
- **Giao diện hiện đại**: UI/UX được thiết kế đẹp mắt và dễ sử dụng

## Cấu trúc dự án

```
lib/
├── models/          # Các model dữ liệu
├── services/        # Các service gọi API
├── providers/       # State management
├── screens/         # Các màn hình
├── widgets/         # Các widget tái sử dụng
└── routers/         # Định tuyến ứng dụng
```

## API Integration

### Chi tiết sản phẩm

Ứng dụng tích hợp với WooCommerce API để lấy và cập nhật thông tin sản phẩm:

- **Endpoint**: `https://kochamtoys.pl/wp-json/wc/v3/products/{id}`
- **Authentication**: Basic Auth với Consumer Key và Consumer Secret
- **Methods**: GET (lấy thông tin), PUT (cập nhật)

### Các trường dữ liệu chính

- Thông tin cơ bản: tên, mô tả, giá, SKU
- Meta data: PACZKA, Karton, Kho hàng
- Hình ảnh sản phẩm
- Thông tin phân loại và trạng thái

## Cài đặt và chạy

1. Clone dự án
2. Chạy `flutter pub get` để cài đặt dependencies
3. Chạy `flutter run` để khởi động ứng dụng

## Dependencies

- `flutter`: Framework chính
- `go_router`: Định tuyến
- `provider`: State management
- `http`: Gọi API
- `flutter_secure_storage`: Lưu trữ bảo mật
- `google_fonts`: Font chữ
- `fl_chart`: Biểu đồ

## Tính năng mới

### Tích hợp API chi tiết sản phẩm

- ✅ Model Product hoàn chỉnh với tất cả trường từ API
- ✅ Service ProductService để gọi API
- ✅ Màn hình ProductDetail với form chỉnh sửa
- ✅ Hiển thị hình ảnh sản phẩm
- ✅ Cập nhật thông tin sản phẩm
- ✅ Xử lý lỗi và loading states
- ✅ Hiển thị thông tin bổ sung (SKU, trạng thái, danh mục, ngày tạo)
