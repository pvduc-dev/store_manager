import 'package:hive/hive.dart';

part 'offline_cart.g.dart';

@HiveType(typeId: 0)
class OfflineCart extends HiveObject {
  @HiveField(0)
  List<OfflineCartItem> items;

  @HiveField(1)
  String totalPrice;

  @HiveField(2)
  int itemsCount;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  OfflineCart({
    required this.items,
    required this.totalPrice,
    required this.itemsCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OfflineCart.empty() {
    return OfflineCart(
      items: [],
      totalPrice: '0',
      itemsCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  void addItem(OfflineCartItem item) {
    final existingIndex = items.indexWhere((element) => element.productId == item.productId);
    
    if (existingIndex != -1) {
      // Cập nhật số lượng nếu sản phẩm đã tồn tại
      items[existingIndex] = items[existingIndex].copyWith(
        quantity: items[existingIndex].quantity + item.quantity,
      );
    } else {
      // Thêm sản phẩm mới
      items.add(item);
    }
    
    _updateTotals();
  }

  void updateItemQuantity(int productId, int quantity) {
    final index = items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        items.removeAt(index);
      } else {
        items[index] = items[index].copyWith(quantity: quantity);
      }
      _updateTotals();
    }
  }

  void updateItemPrice(int productId, String newPrice) {
    final index = items.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      items[index] = items[index].copyWith(price: newPrice);
      _updateTotals();
    }
  }

  void removeItem(int productId) {
    items.removeWhere((item) => item.productId == productId);
    _updateTotals();
  }

  void clear() {
    items.clear();
    _updateTotals();
  }

  void _updateTotals() {
    itemsCount = items.fold(0, (sum, item) => sum + item.quantity);
    totalPrice = items.fold(0.0, (sum, item) => sum + (double.parse(item.price) * item.quantity)).toString();
    updatedAt = DateTime.now();
  }

  OfflineCartItem? getItem(int productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (e) {
      return null;
    }
  }

  bool hasItem(int productId) {
    return items.any((item) => item.productId == productId);
  }
}

@HiveType(typeId: 1)
class OfflineCartItem {
  @HiveField(0)
  final int productId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String price;

  @HiveField(3)
  final int quantity;

  @HiveField(4)
  final String? imageUrl;

  @HiveField(5)
  final String? description;

  @HiveField(6)
  final DateTime addedAt;

  OfflineCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.description,
    required this.addedAt,
  });

  OfflineCartItem copyWith({
    int? productId,
    String? name,
    String? price,
    int? quantity,
    String? imageUrl,
    String? description,
    DateTime? addedAt,
  }) {
    return OfflineCartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => double.parse(price) * quantity;
}
