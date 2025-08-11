import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';
import 'package:store_manager/services/cart_service.dart';
import 'package:store_manager/services/nonce_service.dart';


class CartProvider extends ChangeNotifier {
  Cart? cart;
  bool isLoading = false;

  /// Tạo cart rỗng
  Cart _createEmptyCart() {
    return Cart(
      items: [],
      coupons: [],
      fees: [],
      totals: CartTotals.empty(),
      shippingAddress: Address.empty(),
      billingAddress: Address.empty(),
      needsPayment: false,
      needsShipping: false,
      paymentRequirements: [],
      hasCalculatedShipping: false,
      shippingRates: [],
      itemsCount: 0,
      itemsWeight: 0.0,
      crossSells: [],
      errors: [],
      paymentMethods: [],
      extensions: {},
    );
  }

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

  Future<void> addItemToCart(String productId, {int quantity = 1, String? price}) async {
    try {
      isLoading = true;
      notifyListeners();
      
      print('API: Adding item to cart...');
      
      // Lấy nonce header từ service
      final nonce = await NonceService.getNonce();
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      final newCart = await CartService.addItem(productId, nonce, quantity: quantity, price: price);
      
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
      print('API: Got nonce for clear cart: ${nonce.substring(0, 8)}...');
      
      // API đã trả về Cart object mới, không cần gọi getCart() thêm
      cart = await CartService.clearCart(nonce);
      print('API: Clear cart thành công');
    } catch (e) {
      print('API: Lỗi khi clear cart: $e');
      
      // Nếu là lỗi type casting, tạo cart rỗng
      if (e.toString().contains('type') && e.toString().contains('subtype')) {
        print('API: Lỗi type casting, tạo cart rỗng');
        cart = _createEmptyCart();
        print('API: Đã tạo cart rỗng thay thế');
      }
      // Nếu là lỗi authentication, thử refresh cart thay vì clear
      else if (e.toString().contains('401') || e.toString().contains('Authentication failed')) {
        print('API: Lỗi 401, thử refresh cart thay vì clear');
        try {
          cart = await CartService.getCart();
          print('API: Refresh cart thành công sau lỗi 401');
        } catch (refreshError) {
          print('API: Lỗi khi refresh cart: $refreshError');
          // Không rethrow vì đơn hàng đã tạo thành công
        }
      } else {
        // Với các lỗi khác, vẫn rethrow để UI có thể handle
        rethrow;
      }
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
    final rawPrice = cart?.totals.totalPrice ?? '0';
    // Chuyển đổi từ cents sang złoty
    final cents = int.tryParse(rawPrice) ?? 0;
    return '${(cents / 100.0).toStringAsFixed(2)} zł';
  }
  
  /// Kiểm tra cart có trống hay không
  bool get isEmpty => itemCount == 0;
}