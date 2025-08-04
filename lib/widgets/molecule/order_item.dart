import 'package:flutter/material.dart';
import 'package:store_manager/models/order.dart';

class OrderItem extends StatelessWidget {
  final Order order;
  const OrderItem({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(order.id.toString()),
      subtitle: Text(order.customerName),
      trailing: Text(order.amount.toString()),
      
    );
  }
}