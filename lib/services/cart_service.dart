import 'dart:convert';
import '../models/cart.dart';
import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartService {
  static const String _cartKey = 'cart_data';
  
  // Singleton pattern
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  /// Lấy danh sách giỏ hàng từ local storage
  Future<Cart> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);
      
      if (cartJson != null) {
        print('CartService.getCart: found cart data, length=${cartJson.length}');
        final cartMap = json.decode(cartJson) as Map<String, dynamic>;
        final cart = Cart.fromJson(cartMap);
        print('CartService.getCart: loaded cart with ${cart.items.length} items');
        for (var item in cart.items) {
          print('  Item ${item.product.id}: quantity=${item.quantity}, price=${item.price}, totalPrice=${item.totalPrice}');
        }
        return cart;
      } else {
        print('CartService.getCart: no cart data found');
      }
    } catch (e) {
      print('Lỗi khi đọc giỏ hàng: $e');
    }
    
    // Trả về giỏ hàng rỗng nếu không có dữ liệu
    print('CartService.getCart: returning empty cart');
    return Cart(
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      total: 0.0,
    );
  }

  /// Lưu giỏ hàng vào local storage
  Future<bool> saveCart(Cart cart) async {
    try {
      print('CartService.saveCart: saving cart with ${cart.items.length} items');
      for (var item in cart.items) {
        print('  Item ${item.product.id}: quantity=${item.quantity}, price=${item.price}, totalPrice=${item.totalPrice}');
      }
      
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(cart.toJson());
      print('CartService.saveCart: cart JSON length=${cartJson.length}');
      return await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Lỗi khi lưu giỏ hàng: $e');
      return false;
    }
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<Cart> addToCart(Product product, {int quantity = 1}) async {
    print('CartService.addToCart: product=${product.id}, quantity=$quantity');
    final currentCart = await getCart();
    final updatedCart = currentCart.addItem(product, quantity: quantity);
    print('CartService.addToCart: updated cart has ${updatedCart.items.length} items');
    for (var item in updatedCart.items) {
      print('  Item ${item.product.id}: quantity=${item.quantity}, price=${item.price}, totalPrice=${item.totalPrice}');
    }
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Cập nhật 1 item trong giỏ hàng (số lượng và/hoặc giá)
  Future<Cart> updateItem(int productId, {int? quantity, double? price}) async {
    final currentCart = await getCart();
    final updatedCart = currentCart.updateItem(productId, quantity: quantity, price: price);
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Xóa 1 item trong giỏ hàng
  Future<Cart> removeItem(int productId) async {
    final currentCart = await getCart();
    final updatedCart = currentCart.removeItem(productId);
    await saveCart(updatedCart);
    return updatedCart;
  }

  /// Xóa toàn bộ giỏ hàng
  Future<Cart> clearCart() async {
    final emptyCart = Cart(
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      total: 0.0,
    );
    await saveCart(emptyCart);
    return emptyCart;
  }
}
