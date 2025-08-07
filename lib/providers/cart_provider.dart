import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';
import 'package:store_manager/services/cart_service.dart';

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

  Future<void> updateItemQuantity(String cartItemKey, int quantity) async {
    try {
      isLoading = true;
      notifyListeners();
      // TODO: Cần nonce header cho API
      // cart = await CartService.updateItem(cartItemKey, quantity, nonceHeader);
      
      // Tạm thời update local cho demo
      if (cart != null) {
        final itemIndex = cart!.items.indexWhere((item) => item.key == cartItemKey);
        if (itemIndex != -1) {
          // Do CartItem immutable, ta cần reload lại cart từ server
          await getCart();
        }
      }
    } catch (e) {
      print('Error updating item quantity: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateItemPrice(String cartItemKey, String newPrice) async {
    try {
      isLoading = true;
      notifyListeners();
      // TODO: Cần API endpoint để update giá sản phẩm
      // Hiện tại chưa có API cho việc này, có thể cần custom API
      
      // Tạm thời log cho demo
      print('Updating price for item $cartItemKey to $newPrice');
      
      // Reload cart để có data mới nhất
      await getCart();
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
      // TODO: Cần nonce header cho API
      // cart = await CartService.removeItem(cartItemKey, nonceHeader);
      
      // Tạm thời remove local cho demo
      if (cart != null) {
        // Do Cart immutable, ta cần reload lại cart từ server
        await getCart();
      }
    } catch (e) {
      print('Error removing item: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearCart() async {
    try {
      isLoading = true;
      notifyListeners();
      // TODO: Cần nonce header cho API
      // cart = await CartService.clearCart(nonceHeader);
      
      // Tạm thời clear local cho demo
      await getCart();
    } catch (e) {
      print('Error clearing cart: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  int get itemCount => cart?.itemsCount ?? 0;
  String get totalPrice => cart?.totals.totalPrice ?? '0';
}