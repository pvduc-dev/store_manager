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

  /// Cập nhật đơn hàng
  static Future<Order?> updateOrder({
    required int orderId,
    required Map<String, dynamic> billingInfo,
    required List<Map<String, dynamic>> lineItems,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Płatność przy odbiorze',
    String? customerNote,
    List<Map<String, dynamic>>? feeLines,
  }) async {
    try {
      final orderData = {
        'payment_method': paymentMethod,
        'payment_method_title': paymentMethodTitle,
        'billing': billingInfo,
        'shipping': billingInfo, // Use billing info for shipping too
        'line_items': lineItems,
        'fee_lines': feeLines ?? [],
        'customer_note': customerNote ?? '',
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

  /// Tạo đơn hàng mới
  static Future<Order?> createOrder({
    required Map<String, dynamic> billingInfo,
    required List<Map<String, dynamic>> lineItems,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Płatność przy odbiorze',
    String? customerNote,
    List<Map<String, dynamic>>? feeLines,
  }) async {
    try {
      final orderData = {
        'payment_method': paymentMethod,
        'payment_method_title': paymentMethodTitle,
        'set_paid': false,
        'status': 'processing',
        'billing': billingInfo,
        'shipping': billingInfo, // Use billing info for shipping too
        'line_items': lineItems,
        'fee_lines': feeLines ?? [],
        'customer_note': customerNote ?? '',
      };

      final response = await Dio().post(
        '$baseUrl/orders',
        data: orderData,
        options: Options(headers: {'Authorization': basicAuth})
      );
      return Order.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      print('Error creating order: $e');
      if (e is DioException) {
        print('Error details: ${e.response?.data}');
      }
      return null;
    }
  }
}