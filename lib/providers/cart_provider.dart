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
      cart = await CartService.getCart();
    } catch (e) {
      // Handle error - có thể show snackbar hoặc log error
      print('Error loading cart: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItemToCart(String productId, {int quantity = 1}) async {
    try {
      isLoading = true;
      notifyListeners();
      
      print('CartProvider: Adding item $productId with quantity $quantity');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      final newCart = await CartService.addItem(productId, nonce, quantity: quantity);
      
      print('CartProvider: Received new cart with ${newCart.items.length} items');
      print('CartProvider: New cart total: ${newCart.totals.totalPrice}');
      
      cart = newCart;
      
      print('CartProvider: Cart updated successfully');
    } catch (e) {
      print('CartProvider: Error adding item to cart: $e');
      // Nếu có lỗi, thử refresh cart để đảm bảo UI sync với server
      try {
        await refreshCart();
        print('CartProvider: Cart refreshed after error');
      } catch (refreshError) {
        print('CartProvider: Error refreshing cart: $refreshError');
      }
      rethrow; // Rethrow để UI có thể handle error
    } finally {
      isLoading = false;
      notifyListeners();
      print('CartProvider: addItemToCart completed, isLoading: $isLoading');
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
      
      print('CartProvider: Updating item $cartItemKey to quantity $quantity');
      print('CartProvider: Current cart has ${cart?.items.length ?? 0} items before update');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      
      // Thử update item
      final newCart = await CartService.updateItem(cartItemKey, quantity, nonce);
      
      print('CartProvider: Received updated cart with ${newCart.items.length} items');
      print('CartProvider: Updated cart total: ${newCart.totals.totalPrice}');
      
      // Validate cart data trước khi assign
      if (!_validateCartData(newCart)) {
        print('CartProvider: WARNING - New cart data is invalid, using fallback');
        // Fallback: refresh cart từ server
        await refreshCart();
      } else if (newCart.items.isEmpty && backupCart != null && backupCart.items.isNotEmpty) {
        print('CartProvider: WARNING - New cart is empty but backup had items, using fallback');
        // Fallback: refresh cart từ server
        await refreshCart();
      } else {
        cart = newCart;
        print('CartProvider: Cart quantity updated successfully');
      }
      
    } catch (e) {
      print('CartProvider: Error updating item quantity: $e');
      
      // Restore backup cart
      cart = backupCart;
      print('CartProvider: Restored backup cart');
      
      // Thử refresh cart để đảm bảo UI sync với server
      try {
        await refreshCart();
        print('CartProvider: Cart refreshed after update error');
      } catch (refreshError) {
        print('CartProvider: Error refreshing cart: $refreshError');
      }
      rethrow; // Rethrow để UI có thể handle error
    } finally {
      isLoading = false;
      notifyListeners();
      print('CartProvider: updateItemQuantity completed, final cart has ${cart?.items.length ?? 0} items');
    }
  }

  Future<void> updateItemPrice(String cartItemKey, String newPrice) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // TODO: Cần API endpoint để update giá sản phẩm
      // Hiện tại chưa có API cho việc này, có thể cần custom API
      // Khi có API, sẽ trả về Cart object mới và không cần gọi getCart()
      
      // Tạm thời log cho demo và reload cart
      print('Updating price for item $cartItemKey to $newPrice');
      
      // Chỉ reload khi thực sự cần thiết (khi chưa có API riêng)
      cart = await CartService.getCart();
    } catch (e) {
      print('Error updating item price: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeItem(String cartItemKey) async {
    try {
      isLoading = true;
      notifyListeners();
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      cart = await CartService.removeItem(cartItemKey, nonce);
    } catch (e) {
      print('Error removing item: $e');
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
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      cart = await CartService.clearCart(nonce);
    } catch (e) {
      print('Error clearing cart: $e');
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
    print('CartProvider: Force notifying listeners');
    notifyListeners();
  }

  /// Validate cart data integrity
  bool _validateCartData(Cart? cartData) {
    if (cartData == null) {
      print('CartProvider: Cart data is null');
      return false;
    }
    
    if (cartData.totals.totalPrice.isEmpty || cartData.totals.totalPrice == '0') {
      print('CartProvider: Cart total price is empty or zero');
    }
    
    print('CartProvider: Cart validation - ${cartData.items.length} items, total: ${cartData.totals.totalPrice}');
    return true;
  }

  /// Kiểm tra xem cart có dữ liệu hay không
  bool get hasCartData => cart != null;

  /// Lấy số lượng items trong cart
  int get itemCount {
    final count = cart?.itemsCount ?? 0;
    print('CartProvider: itemCount getter called, returning: $count');
    return count;
  }
  
  /// Lấy tổng giá trị cart
  String get totalPrice {
    final price = cart?.totals.totalPrice ?? '0';
    print('CartProvider: totalPrice getter called, returning: $price');
    return price;
  }
  
  /// Kiểm tra cart có trống hay không
  bool get isEmpty => itemCount == 0;
}