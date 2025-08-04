import 'package:flutter/material.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];

  Map<int, Order> _ordersMap = {};

  bool _isLoading = false;

  List<Order> get orders => _orders;

  Map<int, Order> get ordersMap => _ordersMap;

  bool get isLoading => _isLoading;

  Future<void> loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await OrderService.getOrders();
      _orders = response;
      _ordersMap = Map.fromEntries(
        response.map((order) => MapEntry(order.id, order)),
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Order? getOrderById(int id) {
    return _ordersMap[id];
  }
}