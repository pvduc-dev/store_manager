import 'package:dio/dio.dart';
import 'package:store_manager/models/cart.dart';

class CartService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/store/v1';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      },
    ),
  );

  static Future<Cart> getCart() async {
    final response = await Dio().get(
      '$baseUrl/cart',
      options: Options(headers: {'Authorization': basicAuth}),
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(response.data);
    } else {
      throw Exception('Failed to load cart');
    }
  }

  static Future<Cart> addItem(String productId, String nonceHeader) async {
    final response = await Dio().post(
      '$baseUrl/cart/add-item',
      data: {'product_id': productId, 'quantity': 1},
      options: Options(
        headers: {'Authorization': basicAuth, 'Nonce': nonceHeader},
      ),
    );

    if (response.statusCode == 201) {
      return Cart.fromJson(response.data);
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  static Future<Cart> updateItem(
      String carItemKey, int quantity, String nonceHeader) async {
    final response = await Dio().put(
      '$baseUrl/cart/update-item',
      data: {'cart_item_key': carItemKey, 'quantity': quantity},
      options: Options(
        headers: {'Authorization': basicAuth, 'Nonce': nonceHeader},
      ),
    );

    if (response.statusCode == 201) {
      return Cart.fromJson(response.data);
    } else {
      throw Exception('Failed to update item in cart');
    }
  }

  static Future<Cart> removeItem(String carItemKey, String nonceHeader) async {
    final response = await Dio().post(
      '$baseUrl/cart/remove-item',
      data: {'cart_item_key': carItemKey},
      options: Options(
        headers: {'Authorization': basicAuth, 'Nonce': nonceHeader},
      ),
    );

    if (response.statusCode == 201) {
      return Cart.fromJson(response.data);
    } else {
      throw Exception('Failed to remove item from cart');
    }
  }

  static Future<Cart> clearCart(String nonceHeader) async {
    final response = await Dio().delete(
      '$baseUrl/cart/items',
      options: Options(
        headers: {'Authorization': basicAuth, 'Nonce': nonceHeader},
      ),
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(response.data);
    } else {
      throw Exception('Failed to clear cart');
    }
  }
}
