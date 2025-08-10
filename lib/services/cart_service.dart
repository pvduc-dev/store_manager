import 'package:dio/dio.dart';
import 'package:store_manager/models/cart.dart';
import 'package:store_manager/services/nonce_service.dart';

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
    try {
      final response = await dio.get(
        '/cart',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Cart.fromJson(response.data);
      } else {
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to load cart: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Cart> addItem(String productId, String nonceHeader, {int quantity = 1}) async {
    try {
      final headers = <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      };
      
      // Thêm nonce header nếu có
      if (nonceHeader.isNotEmpty) {
        headers['X-WC-Store-API-Nonce'] = nonceHeader;
        headers['Nonce'] = nonceHeader; // Thêm cả 2 format để đảm bảo
      }



      final response = await dio.post(
        '/cart/add-item',
        data: {
          'id': int.parse(productId), // WooCommerce API expects 'id' not 'product_id'
          'quantity': quantity,
        },
        options: Options(headers: headers),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Cập nhật nonce mới nếu có trong response
        _updateNonceFromResponse(response);
        return Cart.fromJson(response.data);
      } else {
        throw Exception('Failed to add item to cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to add item to cart: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Cart> updateItem(
      String cartItemKey, int quantity, String nonceHeader) async {
    try {
      final headers = <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      };
      
      // Thêm nonce header nếu có
      if (nonceHeader.isNotEmpty) {
        headers['X-WC-Store-API-Nonce'] = nonceHeader;
        headers['Nonce'] = nonceHeader; // Thêm cả 2 format để đảm bảo
      }



      final response = await dio.put(
        '/cart/items/$cartItemKey',
        data: {'quantity': quantity},
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Cập nhật nonce mới nếu có trong response
        _updateNonceFromResponse(response);
        
        return Cart.fromJson(response.data);
      } else {
        throw Exception('Failed to update item in cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to update item: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Cập nhật nonce từ response headers
  static void _updateNonceFromResponse(Response response) {
    final newNonce = response.headers.value('X-WC-Store-API-Nonce') ??
                    response.headers.value('Nonce') ??
                    response.headers.value('x-wc-store-api-nonce');
    
    if (newNonce != null && newNonce.isNotEmpty) {
      // Cập nhật nonce trong NonceService
      NonceService.updateNonce(newNonce);
    }
  }

  static Future<Cart> removeItem(String cartItemKey, String nonceHeader) async {
    try {
      final headers = <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      };
      
      if (nonceHeader.isNotEmpty) {
        headers['X-WC-Store-API-Nonce'] = nonceHeader;
      }

      final response = await dio.delete(
        '/cart/items/$cartItemKey',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cart.fromJson(response.data);
      } else {
        throw Exception('Failed to remove item from cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to remove item: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  static Future<Cart> clearCart(String nonceHeader) async {
    try {
      final headers = <String, String>{
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      };
      
      if (nonceHeader.isNotEmpty) {
        headers['X-WC-Store-API-Nonce'] = nonceHeader;
      }

      final response = await dio.delete(
        '/cart/items',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cart.fromJson(response.data);
      } else {
        throw Exception('Failed to clear cart: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to clear cart: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
