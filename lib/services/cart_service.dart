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

  static Future<Cart> addItem(String productId, String nonceHeader, {int quantity = 1, String? price}) async {
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

      // Chuẩn bị data payload
      final Map<String, dynamic> data = {
        'id': int.parse(productId), // WooCommerce API expects 'id' not 'product_id'
        'quantity': quantity,
      };

      // Thêm price nếu có - WooCommerce API sử dụng đơn vị cents
      if (price != null && price.isNotEmpty) {
        final priceValue = double.tryParse(price) ?? 0.0;
        // Chuyển đổi từ złoty sang cents (nhân với 100)
        data['price'] = (priceValue * 100).round();
      }

      final response = await dio.post(
        '/cart/add-item',
        data: data,
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

  /// Tạo cart rỗng
  static Cart _createEmptyCart() {
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
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('CartService: Lần thử ${retryCount + 1}/$maxRetries - Bắt đầu clear cart...');
        
        // Kiểm tra authentication trước khi thực hiện
        if (retryCount > 0) {
          print('CartService: Kiểm tra authentication trước khi retry...');
          final isAuthenticated = await NonceService.checkAuthentication();
          if (!isAuthenticated) {
            print('CartService: Authentication failed, thử refresh...');
            final refreshSuccess = await NonceService.refreshAuthentication();
            if (!refreshSuccess) {
              throw Exception('Failed to refresh authentication');
            }
          }
        }
        
        // Lấy nonce mới nếu cần thiết
        String currentNonce = nonceHeader;
        if (retryCount > 0 || currentNonce.isEmpty) {
          print('CartService: Lấy nonce mới cho lần thử ${retryCount + 1}');
          currentNonce = await NonceService.getNonce();
        }
        
        final headers = <String, String>{
          'Authorization': basicAuth,
          'Content-Type': 'application/json',
        };
        
        if (currentNonce.isNotEmpty) {
          headers['X-WC-Store-API-Nonce'] = currentNonce;
          headers['Nonce'] = currentNonce; // Thêm cả 2 format
          print('CartService: Sử dụng nonce: ${currentNonce.substring(0, 8)}...');
        }

        final response = await dio.delete(
          '/cart/items',
          options: Options(
            headers: headers,
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            validateStatus: (status) {
              return status != null && status < 500;
            },
          ),
        );

        print('CartService: Clear cart response status: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('CartService: Clear cart thành công');
          
          // Xử lý response từ clear cart API
          if (response.data is List) {
            print('CartService: Response là List (cart đã được clear)');
            // Tạo cart rỗng
            return _createEmptyCart();
          } else if (response.data is Map<String, dynamic>) {
            print('CartService: Response là Map, parse thành Cart object');
            return Cart.fromJson(response.data);
          } else {
            print('CartService: Response type không xác định: ${response.data.runtimeType}');
            // Fallback: tạo cart rỗng
            return _createEmptyCart();
          }
        } else if (response.statusCode == 401) {
          print('CartService: Lỗi 401 - Unauthorized, thử lại với nonce mới');
          retryCount++;
          if (retryCount < maxRetries) {
            // Xóa cache nonce và thử lại
            NonceService.clearNonce();
            await Future.delayed(const Duration(seconds: 1));
            continue;
          } else {
            throw Exception('Failed to clear cart: Authentication failed after $maxRetries attempts');
          }
        } else {
          print('CartService: Lỗi HTTP ${response.statusCode}: ${response.data}');
          throw Exception('Failed to clear cart: HTTP ${response.statusCode}');
        }
        
      } on DioException catch (e) {
        retryCount++;
        print('CartService: Lần thử $retryCount/$maxRetries - DioException: ${e.type} - ${e.message}');
        
        if (e.response != null) {
          print('CartService: Response status: ${e.response?.statusCode}');
          print('CartService: Response data: ${e.response?.data}');
          
          // Nếu là lỗi 401, thử lại với nonce mới
          if (e.response?.statusCode == 401) {
            if (retryCount < maxRetries) {
              print('CartService: Lỗi 401, xóa cache nonce và thử lại...');
              NonceService.clearNonce();
              await Future.delayed(const Duration(seconds: 1));
              continue;
            } else {
              throw Exception('Failed to clear cart: Authentication failed after $maxRetries attempts');
            }
          }
        }
        
        // Nếu là lỗi timeout hoặc connection, thử lại
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.connectionError) {
          
          if (retryCount < maxRetries) {
            print('CartService: Lỗi timeout/connection, đợi 2 giây và thử lại...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        }
        
        // Nếu đã thử hết số lần hoặc lỗi không thể retry
        if (retryCount >= maxRetries) {
          print('CartService: Đã thử hết $maxRetries lần, dừng thử lại');
          throw Exception('Failed to clear cart: ${e.message}');
        }
      } catch (e) {
        print('CartService: Unexpected error khi clear cart: $e');
        throw Exception('Unexpected error: $e');
      }
    }
    
    throw Exception('Failed to clear cart after $maxRetries attempts');
  }
}
