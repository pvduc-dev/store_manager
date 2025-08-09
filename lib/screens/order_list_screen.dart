import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.loadMoreOrders();
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _searchController.clear(); // Clear search field khi refresh
    await orderProvider.loadOrders(refresh: true);
  }

  void _handleSearch() {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.searchOrders(_searchController.text);
  }

  void _clearSearch() {
    _searchController.clear();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (value) => _handleSearch(),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                            hintText: 'Tìm kiếm theo mã đơn hàng hoặc thông tin khách hàng',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: orderProvider.isSearching
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: Colors.grey),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      if (!orderProvider.isSearching) ...[
                        Container(
                          height: 48,
                          width: 1,
                          color: Colors.grey[300],
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _handleSearch(),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              child: const Icon(
                                Icons.search,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Order List
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orderProvider.orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _onRefresh(context),
                    child: ListView(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Center(
                            child: Text(
                              orderProvider.isSearching 
                                  ? 'Không tìm thấy đơn hàng với mã "${orderProvider.searchQuery}"'
                                  : 'Không có đơn hàng nào',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _onRefresh(context),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: orderProvider.orders.length + 
                        (orderProvider.hasMoreData && !orderProvider.isSearching ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == orderProvider.orders.length && !orderProvider.isSearching) {
                        // Load more indicator (chỉ hiển thị khi không tìm kiếm)
                        return orderProvider.isLoadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      
                      final order = orderProvider.orders[index];
                      return _buildOrderItem(context, order);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    return GestureDetector(
      onTap: () {
        context.push('/orders/${order.id}');
      },
      child: Container(
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
                    const Icon(
                      Icons.receipt_long,
                      color: Colors.blue,
                      size: 20,
                    ),
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
                  _formatDateTime(order.dateCreated),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Text(
                  order.billing.firstName.isNotEmpty
                      ? order.billing.firstName
                      : 'Khách hàng #${order.customerId}',
                  style: const TextStyle(fontSize: 14),
                ),
                Spacer(),
                Text(order.orderStatus.displayName),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.formatWithSymbol(double.parse(order.total), order.currencySymbol),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getAmountColor(order.orderStatus),
                  ),
                ),
                Text(
                  '${order.lineItems.length} sản phẩm',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAmountColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.unpaid:
      case OrderStatus.onHold:
      case OrderStatus.pending:
        return Colors.red;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.paid:
      case OrderStatus.completed:
        return Colors.blue;
      case OrderStatus.cancelled:
      case OrderStatus.failed:
        return Colors.grey;
      case OrderStatus.refunded:
        return Colors.purple;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }
}
