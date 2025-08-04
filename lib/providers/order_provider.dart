import 'package:flutter/material.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];

  List<Order> get orders => _orders;

  Future<void> fetchOrders() async {
    final orders = await OrderService.getOrders();
    _orders = orders;
    notifyListeners();
  }
}