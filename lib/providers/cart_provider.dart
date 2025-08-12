import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart' as product_model;
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  Cart _cart = Cart(
    items: [],
    subtotal: 0.0,
    tax: 0.0,
    total: 0.0,
  );
  
  bool _isLoading = false;
  String? _error;

  // Getters
  Cart get cart => _cart;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Computed getters
  int get itemCount => _cart.itemCount;
  int get uniqueItemCount => _cart.uniqueItemCount;
  bool get isEmpty => _cart.isEmpty;
  bool get isNotEmpty => _cart.isNotEmpty;
  double get subtotal => _cart.subtotal;
  double get tax => _cart.tax;
  double get total => _cart.total;

  /// Khởi tạo provider và load dữ liệu từ local storage
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadCart();
      _setError(null);
    } catch (e) {
      _setError('Lỗi khi khởi tạo giỏ hàng: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load giỏ hàng từ local storage
  Future<void> _loadCart() async {
    try {
      _cart = await _cartService.getCart();
      notifyListeners();
    } catch (e) {
      _setError('Lỗi khi load giỏ hàng: $e');
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<void> addToCart(product_model.Product product, {int quantity = 1}) async {
    print('=== DEBUG CART PROVIDER ADD TO CART ===');
    print('Product ID: ${product.id}');
    print('Product Name: ${product.name}');
    print('Quantity: $quantity');
    print('Product Meta Data:');
    for (var meta in product.metaData) {
      print('  ${meta.key}: ${meta.value}');
    }
    
    _setLoading(true);
    try {
      _cart = await _cartService.addToCart(product, quantity: quantity);
      print('Cart updated, items count: ${_cart.items.length}');
      for (var item in _cart.items) {
        print('  Item ${item.product.id}: quantity=${item.quantity}, price=${item.price}, totalPrice=${item.totalPrice}');
      }
      _setError(null);
      notifyListeners();
    } catch (e) {
      print('Error in CartProvider.addToCart: $e');
      _setError('Lỗi khi thêm sản phẩm vào giỏ hàng: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cập nhật 1 item trong giỏ hàng (số lượng và/hoặc giá)
  Future<void> updateItem(int productId, {int? quantity, double? price}) async {
    _setLoading(true);
    try {
      _cart = await _cartService.updateItem(productId, quantity: quantity, price: price);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Lỗi khi cập nhật item: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Xóa 1 item trong giỏ hàng
  Future<void> removeItem(int productId) async {
    _setLoading(true);
    try {
      _cart = await _cartService.removeItem(productId);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Lỗi khi xóa item: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Xóa toàn bộ giỏ hàng
  Future<void> clearCart() async {
    _setLoading(true);
    try {
      _cart = await _cartService.clearCart();
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Lỗi khi xóa giỏ hàng: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh dữ liệu giỏ hàng
  Future<void> refresh() async {
    await _loadCart();
  }

  /// Lấy sản phẩm theo ID từ giỏ hàng
  CartItem? getCartItem(int productId) {
    print('=== DEBUG GET CART ITEM ===');
    print('Looking for product ID: $productId');
    print('Current cart items count: ${_cart.items.length}');
    for (var item in _cart.items) {
      print('  Item ${item.product.id}: quantity=${item.quantity}, price=${item.price}, totalPrice=${item.totalPrice}');
    }
    
    try {
      final foundItem = _cart.items.firstWhere((item) => item.product.id == productId);
      print('Found item: quantity=${foundItem.quantity}, price=${foundItem.price}, totalPrice=${foundItem.totalPrice}');
      return foundItem;
    } catch (e) {
      print('Item not found for product ID: $productId');
      return null;
    }
  }

  /// Lấy số sản phẩm trong giỏ hàng
  int getCartItemCount() {
    return _cart.items.length;
  }

  /// Kiểm tra xem có sản phẩm nào có giá thay đổi không
  bool get hasPriceChanges {
    return _cart.items.any((item) {
      final priceMeta = item.product.metaData.firstWhere(
        (meta) => meta.key == 'custom_price',
        orElse: () => product_model.MetaData(key: 'custom_price', value: '0'),
      );
      
      if (priceMeta.value.isNotEmpty) {
        final originalPrice = double.tryParse(priceMeta.value) ?? 0.0;
        return (item.price - originalPrice).abs() > 0.01;
      }
      return false;
    });
  }

  /// Lấy danh sách sản phẩm có giá thay đổi
  List<CartItem> get itemsWithPriceChanges {
    return _cart.items.where((item) {
      final priceMeta = item.product.metaData.firstWhere(
        (meta) => meta.key == 'custom_price',
        orElse: () => product_model.MetaData(key: 'custom_price', value: '0'),
      );
      
      if (priceMeta.value.isNotEmpty) {
        final originalPrice = double.tryParse(priceMeta.value) ?? 0.0;
        return (item.price - originalPrice).abs() > 0.01;
      }
      return false;
    }).toList();
  }

  // Private methods để cập nhật state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      print('CartProvider Error: $error');
    }
  }

  /// Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
