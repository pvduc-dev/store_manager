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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đồng bộ search controller với provider state
    final orderProvider = Provider.of<OrderProvider>(
      context,
      listen: false,
    );
    _syncSearchController(orderProvider);
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

  void _syncSearchController(OrderProvider orderProvider) {
    // Đồng bộ controller với provider state
    if (orderProvider.searchQuery != _searchController.text) {
      _searchController.text = orderProvider.searchQuery;
    }
  }

  void _performSearch() {
    final orderProvider = Provider.of<OrderProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      orderProvider.searchOrders(query);
    } else {
      orderProvider.clearSearch();
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    _searchController.clear(); // Clear search field khi refresh
    orderProvider.clearSearch();
    await orderProvider.loadOrders(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    orderProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Order List
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProvider, child) {
                  if (orderProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (orderProvider.orders.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => _onRefresh(context),
                      child: ListView(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    orderProvider.isSearching
                                        ? Icons.search_off
                                        : Icons.receipt_long_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    orderProvider.isSearching 
                                        ? 'Không tìm thấy đơn hàng nào'
                                        : 'Chưa có đơn hàng nào',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (orderProvider.isSearching) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Thử tìm kiếm với từ khóa khác',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 8),
                                ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đơn hàng',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: 16),
                          onSubmitted: (_) => _performSearch(),
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm theo mã đơn hàng hoặc thông tin khách hàng',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            suffixIcon: Consumer<OrderProvider>(
                              builder: (context, orderProvider, child) {
                                if (orderProvider.isSearching) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _clearSearch();
                                    },
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              FilledButton(onPressed: _performSearch, child: Text('Tìm kiếm')),
            ],
          ),
        ],
      ),
    );
  }
}
