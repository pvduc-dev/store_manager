import 'package:dio/dio.dart';
import 'package:store_manager/models/order.dart';

class OrderService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3/orders';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Order>> getOrders() async {
    final response = await Dio().get(baseUrl, options: Options(headers: {'Authorization': basicAuth}));
    return response.data.map((e) => Order.fromJson(e)).toList();
  }
}