import 'package:dio/dio.dart';
import 'package:store_manager/models/order.dart';

class OrderService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3/orders?per_page=100';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Order>> getOrders() async {
    final response = await Dio().get(baseUrl, options: Options(headers: {'Authorization': basicAuth}));
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }
}