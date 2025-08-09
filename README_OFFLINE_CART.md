# Giỏ hàng Offline với Hive

## Tổng quan

Dự án này đã được tích hợp giỏ hàng offline sử dụng Hive để lưu trữ dữ liệu locally. Giỏ hàng offline cho phép người dùng:

- Thêm sản phẩm vào giỏ hàng mà không cần kết nối internet
- Chỉnh sửa số lượng và giá sản phẩm
- Xóa sản phẩm khỏi giỏ hàng
- Lưu trữ dữ liệu locally trên thiết bị

## Cấu trúc dự án

### Models
- `lib/models/offline_cart.dart`: Model cho giỏ hàng offline
  - `OfflineCart`: Class chính cho giỏ hàng
  - `OfflineCartItem`: Class cho từng item trong giỏ hàng

### Services
- `lib/services/offline_cart_service.dart`: Service để quản lý giỏ hàng offline
  - Khởi tạo Hive
  - CRUD operations cho giỏ hàng
  - Adapters cho Hive

### Providers
- `lib/providers/cart_provider.dart`: Provider đã được cập nhật để hỗ trợ cả online và offline mode

### Widgets
- `lib/widgets/molecule/offline_cart_item.dart`: Widget hiển thị item trong giỏ hàng offline

### Screens
- `lib/screens/cart_screen.dart`: Màn hình giỏ hàng đã được cập nhật để hỗ trợ cả online và offline mode

## Tính năng

### 1. Chế độ Online/Offline
- Switch trong AppBar để chuyển đổi giữa chế độ online và offline
- Mặc định sử dụng chế độ offline

### 2. Quản lý giỏ hàng offline
- **Thêm sản phẩm**: `addItemToCart()` method
- **Cập nhật số lượng**: `updateItemQuantity()` method
- **Cập nhật giá**: `updateItemPrice()` method
- **Xóa sản phẩm**: `removeItem()` method
- **Xóa toàn bộ**: `clearCart()` method

### 3. UI/UX
- TextField đơn giản cho số lượng và giá (theo yêu cầu của user)
- Không có nút edit, confirm hay hiển thị giá gốc
- Giao diện thân thiện và dễ sử dụng

## Cách sử dụng

### 1. Khởi tạo
```dart
// Trong main.dart
final cartProvider = CartProvider();
await cartProvider.initialize(); // Khởi tạo Hive
```

### 2. Thêm sản phẩm vào giỏ hàng
```dart
await cartProvider.addItemToCart(
  productId: 1,
  name: 'Sản phẩm A',
  sku: 'SP001',
  price: 100000,
  quantity: 2,
  imageUrl: 'https://example.com/image.jpg',
  description: 'Mô tả sản phẩm',
);
```

### 3. Cập nhật số lượng
```dart
await cartProvider.updateItemQuantity(productId: 1, quantity: 3);
```

### 4. Cập nhật giá
```dart
await cartProvider.updateItemPrice(productId: 1, newPrice: 150000);
```

### 5. Xóa sản phẩm
```dart
await cartProvider.removeItem(productId: 1);
```

### 6. Xóa toàn bộ giỏ hàng
```dart
await cartProvider.clearCart();
```

## Dependencies

Đã thêm các dependencies sau vào `pubspec.yaml`:

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  path_provider: ^2.1.4

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.12
```

## Lưu ý

1. **Hive Adapters**: Cần tạo adapters cho Hive để serialize/deserialize objects
2. **Type Safety**: Sử dụng type-safe operations với Hive
3. **Performance**: Hive cung cấp hiệu suất cao cho local storage
4. **Persistence**: Dữ liệu được lưu trữ locally và không bị mất khi restart app

## Troubleshooting

### Lỗi "Target of URI hasn't been generated"
Nếu gặp lỗi này, chạy lệnh sau để generate code:
```bash
flutter packages pub run build_runner build
```

### Lỗi Hive initialization
Đảm bảo đã gọi `await cartProvider.initialize()` trong main.dart trước khi sử dụng.

## Tương lai

- Tích hợp sync giữa offline và online cart
- Backup/restore giỏ hàng
- Export/import giỏ hàng
- Multi-device sync
