import 'package:hive_flutter/hive_flutter.dart';
import 'package:store_manager/models/offline_cart.dart';

class OfflineCartService {
  static const String _cartBoxName = 'offline_cart';
  static const String _cartKey = 'current_cart';
  
  static late Box<OfflineCart> _cartBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Đăng ký adapters được generate tự động
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(OfflineCartAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OfflineCartItemAdapter());
    }
    
    try {
      _cartBox = await Hive.openBox<OfflineCart>(_cartBoxName);
    } catch (e) {
      // Nếu có lỗi (do xung đột format cũ), xóa box và tạo mới
      await Hive.deleteBoxFromDisk(_cartBoxName);
      _cartBox = await Hive.openBox<OfflineCart>(_cartBoxName);
    }
  }

  static Future<OfflineCart> getCart() async {
    final cart = _cartBox.get(_cartKey);
    if (cart == null) {
      final emptyCart = OfflineCart.empty();
      await _cartBox.put(_cartKey, emptyCart);
      return emptyCart;
    }
    return cart;
  }

  static Future<void> saveCart(OfflineCart cart) async {
    await _cartBox.put(_cartKey, cart);
  }

  static Future<void> addItem(OfflineCartItem item) async {
    final cart = await getCart();
    cart.addItem(item);
    await saveCart(cart);
  }

  static Future<void> updateItemQuantity(int productId, int quantity) async {
    final cart = await getCart();
    cart.updateItemQuantity(productId, quantity);
    await saveCart(cart);
  }

  static Future<void> removeItem(int productId) async {
    final cart = await getCart();
    cart.removeItem(productId);
    await saveCart(cart);
  }

  static Future<void> clearCart() async {
    final cart = OfflineCart.empty();
    await saveCart(cart);
  }

  static Future<OfflineCartItem?> getItem(int productId) async {
    final cart = await getCart();
    return cart.getItem(productId);
  }

  static Future<bool> hasItem(int productId) async {
    final cart = await getCart();
    return cart.hasItem(productId);
  }

  static Future<void> close() async {
    await _cartBox.close();
  }

  // Method để clear dữ liệu cũ khi có xung đột
  static Future<void> clearOldData() async {
    await _cartBox.clear();
    final emptyCart = OfflineCart.empty();
    await _cartBox.put(_cartKey, emptyCart);
  }
}


