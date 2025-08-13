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
  String _searchQuery = '';
  int _currentPage = 1;
  static const int _perPage = 20;

  List<Order> get orders => _isSearching ? _filteredOrders : _orders;

  Map<int, Order> get ordersMap => _ordersMap;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
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
      _filteredOrders.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    _isLoading = true;
    notifyListeners();

    try {
      final searchResults = await OrderService.searchOrders(
        search: _searchQuery,
        perPage: 50,
      );
      
      _filteredOrders = searchResults;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error searching orders: $e');
      _filteredOrders = [];
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
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

  Future<Order?> updateOrder({
    required int orderId,
    required Map<String, dynamic> billingInfo,
    required List<Map<String, dynamic>> lineItems,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Thanh toán khi nhận hàng',
    String? customerNote,
    List<Map<String, dynamic>>? feeLines,
  }) async {
    try {
      final updatedOrder = await OrderService.updateOrder(
        orderId: orderId,
        billingInfo: billingInfo,
        lineItems: lineItems,
        paymentMethod: paymentMethod,
        paymentMethodTitle: paymentMethodTitle,
        customerNote: customerNote,
        feeLines: feeLines ?? [],
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
        return updatedOrder;
      }
      return null;
    } catch (e) {
      print('Error updating order: $e');
      return null;
    }
  }

  Future<Order?> createOrder({
    required Map<String, dynamic> billingInfo,
    required List<Map<String, dynamic>> lineItems,
    String paymentMethod = 'cod',
    String paymentMethodTitle = 'Thanh toán khi nhận hàng',
    String? customerNote,
    List<Map<String, dynamic>>? feeLines,
  }) async {
    try {
      final newOrder = await OrderService.createOrder(
        billingInfo: billingInfo,
        lineItems: lineItems,
        paymentMethod: paymentMethod,
        paymentMethodTitle: paymentMethodTitle,
        customerNote: customerNote,
        feeLines: feeLines ?? [],
      );
      
      if (newOrder != null) {
        _orders.insert(0, newOrder);
        _ordersMap[newOrder.id] = newOrder;
        notifyListeners();
        return newOrder;
      }
      return null;
    } catch (e) {
      print('Error creating order: $e');
      return null;
    }
  }
}