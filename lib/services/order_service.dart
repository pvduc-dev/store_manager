import 'package:dio/dio.dart';
import 'package:store_manager/models/order.dart';

class OrderService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Order>> getOrders({int page = 1, int perPage = 20}) async {
    final response = await Dio().get(
      '$baseUrl/orders?per_page=$perPage&page=$page&orderby=date&order=desc',
      options: Options(headers: {'Authorization': basicAuth})
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Tìm kiếm orders theo search query (ID, number, customer name, etc.)
  static Future<List<Order>> searchOrders({
    required String search,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await Dio().get(
      '$baseUrl/orders?search=$search&per_page=$perPage&page=$page&orderby=date&order=desc',
      options: Options(headers: {'Authorization': basicAuth})
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy chi tiết order theo ID
  static Future<Order?> getOrderById(int orderId) async {
    try {
      final response = await Dio().get(
        '$baseUrl/orders/$orderId',
        options: Options(headers: {'Authorization': basicAuth})
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching order $orderId: $e');
      return null;
    }
  }

  /// Cập nhật trạng thái order
  static Future<Order?> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    try {
      final response = await Dio().put(
        '$baseUrl/orders/$orderId',
        data: {'status': status},
        options: Options(headers: {'Authorization': basicAuth})
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error updating order $orderId: $e');
      return null;
    }
  }

  /// Cập nhật toàn bộ thông tin đơn hàng
  static Future<Order?> updateOrder({
    required int orderId,
    required Map<String, dynamic> orderData,
  }) async {
    try {
      print('OrderService: Bắt đầu cập nhật đơn hàng $orderId...');
      print('OrderService: URL: $baseUrl/orders/$orderId');
      print('OrderService: Headers: Authorization: $basicAuth');
      print('OrderService: Data: ${orderData.toString()}');
      
      final response = await Dio().put(
        '$baseUrl/orders/$orderId',
        data: orderData,
        options: Options(
          headers: {'Authorization': basicAuth},
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );
      
      print('OrderService: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('OrderService: Cập nhật đơn hàng thành công!');
        print('OrderService: Response data: ${response.data}');
        return Order.fromJson(response.data as Map<String, dynamic>);
      } else {
        print('OrderService: Lỗi HTTP ${response.statusCode}: ${response.data}');
        throw Exception('HTTP ${response.statusCode}: ${response.data}');
      }
      
    } catch (e) {
      print('OrderService: Lỗi khi cập nhật đơn hàng $orderId: $e');
      if (e is DioException) {
        print('OrderService: DioException type: ${e.type}');
        print('OrderService: DioException message: ${e.message}');
        
        if (e.response != null) {
          print('OrderService: Response status: ${e.response?.statusCode}');
          print('OrderService: Response data: ${e.response?.data}');
        }
      }
      rethrow;
    }
  }

  /// Tạo order mới từ cart và thông tin khách hàng
  static Future<Order?> createOrder({
    required Map<String, dynamic> orderData,
  }) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('OrderService: Lần thử ${retryCount + 1}/$maxRetries - Bắt đầu gọi API tạo đơn hàng...');
        print('OrderService: URL: $baseUrl/orders');
        print('OrderService: Headers: Authorization: $basicAuth');
        
        final response = await Dio().post(
          '$baseUrl/orders',
          data: orderData,
          options: Options(
            headers: {'Authorization': basicAuth},
            sendTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            validateStatus: (status) {
              return status != null && status < 500;
            },
          ),
        );
        
        print('OrderService: Response status: ${response.statusCode}');
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          print('OrderService: Tạo đơn hàng thành công!');
          print('OrderService: Response data: ${response.data}');
          return Order.fromJson(response.data as Map<String, dynamic>);
        } else {
          print('OrderService: Lỗi HTTP ${response.statusCode}: ${response.data}');
          throw Exception('HTTP ${response.statusCode}: ${response.data}');
        }
        
      } catch (e) {
        retryCount++;
        print('OrderService: Lần thử $retryCount/$maxRetries - Lỗi: $e');
        
        if (e is DioException) {
          print('OrderService: DioException type: ${e.type}');
          print('OrderService: DioException message: ${e.message}');
          
          if (e.response != null) {
            print('OrderService: Response status: ${e.response?.statusCode}');
            print('OrderService: Response data: ${e.response?.data}');
            print('OrderService: Response headers: ${e.response?.headers}');
          }
          
          // Nếu là lỗi timeout hoặc connection, thử lại
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError) {
            
            if (retryCount < maxRetries) {
              print('OrderService: Đợi 2 giây trước khi thử lại...');
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
          }
        }
        
        // Nếu đã thử hết số lần hoặc lỗi không phải timeout
        if (retryCount >= maxRetries) {
          print('OrderService: Đã thử hết $maxRetries lần, dừng thử lại');
          rethrow;
        }
      }
    }
    
    throw Exception('Không thể tạo đơn hàng sau $maxRetries lần thử');
  }

  /// Xóa order theo ID
  static Future<bool> deleteOrder(int orderId) async {
    try {
      await Dio().delete(
        '$baseUrl/orders/$orderId',
        options: Options(headers: {'Authorization': basicAuth})
      );
      return true;
    } catch (e) {
      print('Error deleting order $orderId: $e');
      return false;
    }
  }
}