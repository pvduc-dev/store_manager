import 'package:flutter/material.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  List<Order> _orders = [];
  List<Order> _filteredOrders = [];
  
  Map<int, Order> _ordersMap = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _isSearching = false;
  bool _isSearchLoading = false;
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _perPage = 20;

  List<Order> get orders => _isSearching ? _filteredOrders : _orders;

  Map<int, Order> get ordersMap => _ordersMap;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  bool get isSearchLoading => _isSearchLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadOrders({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _orders.clear();
      _ordersMap.clear();
      _isSearching = false;
      _searchQuery = '';
      _filteredOrders.clear();
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await OrderService.getOrders(page: 1, perPage: _perPage);
      _orders = response;
      _ordersMap = Map.fromEntries(
        response.map((order) => MapEntry(order.id, order)),
      );
      _currentPage = 1;
      _hasMoreData = response.length == _perPage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching orders: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await OrderService.getOrders(page: nextPage, perPage: _perPage);
      
      if (response.isNotEmpty) {
        _orders.addAll(response);
        for (final order in response) {
          _ordersMap[order.id] = order;
        }
        _currentPage = nextPage;
        _hasMoreData = response.length == _perPage;
      } else {
        _hasMoreData = false;
      }
      
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      print('Error loading more orders: $e');
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Order? getOrderById(int id) {
    return _ordersMap[id];
  }

  Future<void> searchOrders(String query) async {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      _isSearching = false;
      _isSearchLoading = false;
      _filteredOrders.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    _isSearchLoading = true;
    notifyListeners();

    try {
      // Đầu tiên thử tìm kiếm qua WooCommerce API
      final apiSearchResults = await OrderService.searchOrders(
        search: _searchQuery,
        perPage: 50,
      );
      
      // Nếu có kết quả từ API, sử dụng luôn
      if (apiSearchResults.isNotEmpty) {
        _filteredOrders = apiSearchResults;
        _isSearchLoading = false;
        notifyListeners();
        return;
      }
      
      // Nếu không có kết quả từ API, thực hiện tìm kiếm local
      _filteredOrders = _searchOrdersLocal(_searchQuery);
      _isSearchLoading = false;
      notifyListeners();
      
    } catch (e) {
      print('Error searching orders via API, falling back to local search: $e');
      // Fallback về tìm kiếm local nếu API lỗi
      _filteredOrders = _searchOrdersLocal(_searchQuery);
      _isSearchLoading = false;
      notifyListeners();
    }
  }

  /// Tìm kiếm đơn hàng theo tên KH, NIP, số điện thoại trong dữ liệu local
  List<Order> _searchOrdersLocal(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final results = <Order>[];
    
    for (final order in _orders) {
      // Tìm theo tên khách hàng (first name + last name)
      final customerName = '${order.billing.firstName} ${order.billing.lastName}'.toLowerCase();
      if (customerName.contains(lowerQuery)) {
        results.add(order);
        continue;
      }
      
      // Tìm theo NIP (company)
      if (order.billing.company.toLowerCase().contains(lowerQuery)) {
        results.add(order);
        continue;
      }
      
      // Tìm theo số điện thoại
      if (order.billing.phone.toLowerCase().contains(lowerQuery)) {
        results.add(order);
        continue;
      }
      
      // Tìm theo email
      if (order.billing.email.toLowerCase().contains(lowerQuery)) {
        results.add(order);
        continue;
      }
      
      // Tìm theo mã đơn hàng
      if (order.number.toLowerCase().contains(lowerQuery)) {
        results.add(order);
        continue;
      }
      
      // Tìm theo order ID
      if (order.id.toString().contains(lowerQuery)) {
        results.add(order);
        continue;
      }
    }
    
    return results;
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    _isSearchLoading = false;
    _filteredOrders.clear();
    notifyListeners();
  }

  Future<Order?> loadOrderDetail(int orderId) async {
    try {
      final order = await OrderService.getOrderById(orderId);
      if (order != null) {
        _ordersMap[orderId] = order;
        
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = order;
        }
        
        notifyListeners();
      }
      return order;
    } catch (e) {
      print('Error loading order detail $orderId: $e');
      return null;
    }
  }

  Future<bool> updateOrderStatus(int orderId, String status) async {
    try {
      final updatedOrder = await OrderService.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      
      if (updatedOrder != null) {
        _ordersMap[orderId] = updatedOrder;
        
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
        

        if (_isSearching) {
          final searchIndex = _filteredOrders.indexWhere((o) => o.id == orderId);
          if (searchIndex != -1) {
            _filteredOrders[searchIndex] = updatedOrder;
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  /// Cập nhật toàn bộ thông tin đơn hàng
  Future<Order?> updateOrder(int orderId, Map<String, dynamic> orderData) async {
    try {
      print('OrderProvider: Bắt đầu cập nhật đơn hàng $orderId...');
      _isLoading = true;
      notifyListeners();

      print('OrderProvider: Dữ liệu cập nhật: ${orderData.toString()}');
      
      final updatedOrder = await OrderService.updateOrder(
        orderId: orderId,
        orderData: orderData,
      );
      
      print('OrderProvider: Đơn hàng được cập nhật thành công: ${updatedOrder?.id}');
      
      if (updatedOrder != null) {
        // Cập nhật order trong danh sách
        _ordersMap[orderId] = updatedOrder;
        
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = updatedOrder;
        }
        
        if (_isSearching) {
          final searchIndex = _filteredOrders.indexWhere((o) => o.id == orderId);
          if (searchIndex != -1) {
            _filteredOrders[searchIndex] = updatedOrder;
          }
        }
        
        notifyListeners();
      }
      
      return updatedOrder;
    } catch (e) {
      print('OrderProvider: Lỗi khi cập nhật đơn hàng: $e');
      print('OrderProvider: Stack trace: ${StackTrace.current}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteOrder(int orderId) async {
    try {
      final success = await OrderService.deleteOrder(orderId);
      if (success) {
        _orders.removeWhere((order) => order.id == orderId);
        _ordersMap.remove(orderId);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting order: $e');
      rethrow;
    }
  }

  /// Tạo order mới
  Future<Order?> createOrder(Map<String, dynamic> orderData) async {
    try {
      print('OrderProvider: Bắt đầu tạo đơn hàng...');
      _isLoading = true;
      notifyListeners();

      print('OrderProvider: Dữ liệu đơn hàng: ${orderData.toString()}');
      
      final newOrder = await OrderService.createOrder(orderData: orderData);
      
      print('OrderProvider: Đơn hàng được tạo thành công: ${newOrder?.id}');
      
      if (newOrder != null) {
        // Thêm order mới vào danh sách
        _orders.insert(0, newOrder);
        _ordersMap[newOrder.id] = newOrder;
        
        // Cập nhật UI
        notifyListeners();
      }
      
      return newOrder;
    } catch (e) {
      print('OrderProvider: Lỗi khi tạo đơn hàng: $e');
      print('OrderProvider: Stack trace: ${StackTrace.current}');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}