import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';
import 'package:store_manager/services/cart_service.dart';
import 'package:store_manager/services/nonce_service.dart';

class CartProvider extends ChangeNotifier {
  Cart? cart;
  bool isLoading = false;

  Future<void> getCart() async {
    try {
      isLoading = true;
      notifyListeners();
      print('API: Getting cart...');
      cart = await CartService.getCart();
    } catch (e) {
      // Handle error - có thể show snackbar hoặc log error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItemToCart(String productId, {int quantity = 1}) async {
    try {
      isLoading = true;
      notifyListeners();
      
      print('API: Adding item to cart...');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      final newCart = await CartService.addItem(productId, nonce, quantity: quantity);
      
      cart = newCart;
    } catch (e) {
      // Nếu có lỗi, thử refresh cart để đảm bảo UI sync với server
      try {
        await refreshCart();
      } catch (refreshError) {
        // Silent fail
      }
      rethrow; // Rethrow để UI có thể handle error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isProductInCart(String productId) {
    if (cart == null) return false;
    return cart!.items.any((item) => item.id.toString() == productId);
  }

  Future<void> updateItemQuantity(String cartItemKey, int quantity) async {
    // Backup cart trước khi update
    final backupCart = cart;
    
    try {
      isLoading = true;
      notifyListeners();
      
      print('API: Updating item quantity...');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      
      // Thử update item
      final newCart = await CartService.updateItem(cartItemKey, quantity, nonce);
      
      // Validate cart data trước khi assign
      if (!_validateCartData(newCart)) {
        // Fallback: refresh cart từ server
        await refreshCart();
      } else if (newCart.items.isEmpty && backupCart != null && backupCart.items.isNotEmpty) {
        // Fallback: refresh cart từ server
        await refreshCart();
      } else {
        cart = newCart;
      }
      
    } catch (e) {
      // Restore backup cart
      cart = backupCart;
      
      // Thử refresh cart để đảm bảo UI sync với server
      try {
        await refreshCart();
      } catch (refreshError) {
        // Silent fail
      }
      rethrow; // Rethrow để UI có thể handle error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateItemPrice(String cartItemKey, String newPrice) async {
    try {
      isLoading = true;
      notifyListeners();
      
      print('API: Updating item price...');
      
      // TODO: Cần API endpoint để update giá sản phẩm
      // Hiện tại chưa có API cho việc này, có thể cần custom API
      // Khi có API, sẽ trả về Cart object mới và không cần gọi getCart()
      
      // Chỉ reload khi thực sự cần thiết (khi chưa có API riêng)
      cart = await CartService.getCart();
    } catch (e) {
      // Silent fail
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String cartItemKey) async {
    try {
      isLoading = true;
      notifyListeners();
      
      print('API: Removing item from cart...');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      cart = await CartService.removeItem(cartItemKey, nonce);
    } catch (e) {
      rethrow; // Rethrow để UI có thể handle error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading = true;
      notifyListeners();
      
      print('API: Clearing cart...');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      cart = await CartService.clearCart(nonce);
    } catch (e) {
      rethrow; // Rethrow để UI có thể handle error
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh cart data từ server (chỉ dùng khi thực sự cần thiết)
  Future<void> refreshCart() async {
    await getCart();
  }

  /// Force notify listeners để refresh UI
  void forceNotify() {
    notifyListeners();
  }

  /// Validate cart data integrity
  bool _validateCartData(Cart? cartData) {
    if (cartData == null) {
      return false;
    }
    
    return true;
  }

  /// Kiểm tra xem cart có dữ liệu hay không
  bool get hasCartData => cart != null;

  /// Lấy số lượng items trong cart
  int get itemCount {
    return cart?.itemsCount ?? 0;
  }
  
  /// Lấy tổng giá trị cart
  String get totalPrice {
    return cart?.totals.totalPrice ?? '0';
  }
  
  /// Kiểm tra cart có trống hay không
  bool get isEmpty => itemCount == 0;
}