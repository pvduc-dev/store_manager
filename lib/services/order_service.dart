import 'package:dio/dio.dart';
import 'package:store_manager/models/order.dart';

class OrderService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/v1';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Order>> getOrders({int page = 1, int perPage = 20}) async {
    final response = await Dio().get(
      '$baseUrl/orders?page=$page&per_page=$perPage',
      options: Options(headers: {'Authorization': basicAuth})
    );
    
    // Response is direct array
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
      '$baseUrl/orders?search=$search&page=$page&per_page=$perPage',
      options: Options(headers: {'Authorization': basicAuth})
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Lấy chi tiết order theo ID - Không cần nữa vì list API đã có full data
  static Future<Order?> getOrderById(int orderId) async {
    try {
      // Fallback nếu cần - gọi list API và filter
      final orders = await getOrders(perPage: 100);
      return orders.firstWhere((order) => order.id == orderId);
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

  /// Cập nhật đơn hàng với format mới
  static Future<Order?> updateOrder({
    required int orderId,
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> customer,
    required String customerNote,
    required double taxFee,
  }) async {
    try {
      final orderData = {
        'line_items': lineItems,
        'customer': customer,
        'customer_note': customerNote,
        'tax_fee': taxFee,
      };

      final response = await Dio().put(
        '$baseUrl/orders/$orderId',
        data: orderData,
        options: Options(headers: {'Authorization': basicAuth})
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error updating order $orderId: $e');
      if (e is DioException) {
        print('Error details: ${e.response?.data}');
      }
      return null;
    }
  }

  /// Tạo đơn hàng mới với API custom structure
  static Future<Order?> createOrder({
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> customer,
    required String customerNote,
    required double taxFee,
  }) async {
    try {
      final orderData = {
        'line_items': lineItems,
        'customer': customer,
        'customer_note': customerNote,
        'tax_fee': taxFee,
      };

      final response = await Dio().post(
        '$baseUrl/orders',
        data: orderData,
        options: Options(headers: {'Authorization': basicAuth})
      );
      
      // API trả về order data trực tiếp (giống GET format)
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error creating order: $e');
      if (e is DioException) {
        print('Error details: ${e.response?.data}');
      }
      return null;
    }
  }

  static Future<List<Order>> getOrdersByCustomerId(int customerId) async {
    final response = await Dio().get(
      '$baseUrl/orders?customer=$customerId',
      options: Options(headers: {'Authorization': basicAuth})
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}