import 'package:flutter/material.dart';
import '../models/order.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đặt hàng'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            // Tab Bar
            Container(
              color: Colors.white,
              child: const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: 'Chưa thanh toán'),
                  Tab(text: 'Đang thanh toán'),
                  Tab(text: 'Đã thanh toán'),
                ],
              ),
            ),
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          hintText: 'Vui lòng nhập mã số đơn hàng',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab Bar View
            Expanded(
              child: TabBarView(
                children: [
                  _buildOrderList(OrderStatus.unpaid),
                  _buildOrderList(OrderStatus.processing),
                  _buildOrderList(OrderStatus.paid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(OrderStatus status) {
    final orders = _getMockOrders().where((order) => order.status == status).toList();
    
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderItem(order);
      },
    );
  }

  Widget _buildOrderItem(Order order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    order.id.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDateTime(order.createdAt),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                order.customerName,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${order.amount.toInt()} ${order.currency}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getAmountColor(order.status),
                    ),
                  ),
                  Text(
                    '${order.quantity}pcs ${order.status.displayName}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.currency_exchange, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.store, color: Colors.blue, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getAmountColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.unpaid:
        return Colors.red;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.blue;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  List<Order> _getMockOrders() {
    return [
      Order(
        id: 1,
        customerName: 'Khách 2',
        amount: 574,
        currency: 'zł',
        quantity: 5,
        status: OrderStatus.unpaid,
        createdAt: DateTime(2025, 7, 23, 14, 42, 57),
      ),
      Order(
        id: 2,
        customerName: 'Khách 1',
        amount: 147,
        currency: 'zł',
        quantity: 16,
        status: OrderStatus.unpaid,
        createdAt: DateTime(2025, 7, 19, 11, 40, 38),
      ),
      Order(
        id: 3,
        customerName: 'Khách 3',
        amount: 146,
        currency: 'zł',
        quantity: 19,
        status: OrderStatus.unpaid,
        createdAt: DateTime(2025, 7, 19, 10, 31, 8),
      ),
      Order(
        id: 4,
        customerName: 'Khách 4',
        amount: 31,
        currency: 'zł',
        quantity: 7,
        status: OrderStatus.unpaid,
        createdAt: DateTime(2025, 7, 19, 10, 25, 40),
      ),
      Order(
        id: 5,
        customerName: 'Khách 5',
        amount: 250,
        currency: 'zł',
        quantity: 3,
        status: OrderStatus.processing,
        createdAt: DateTime(2025, 7, 18, 9, 15, 20),
      ),
      Order(
        id: 6,
        customerName: 'Khách 6',
        amount: 89,
        currency: 'zł',
        quantity: 12,
        status: OrderStatus.paid,
        createdAt: DateTime(2025, 7, 17, 16, 30, 45),
      ),
    ];
  }
}