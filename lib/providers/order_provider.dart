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
  
  // Loading order state (tương tự ProductProvider)
  Order? _loadingOrder;
  int _loadingOrderTempId = -1;

  List<Order> get orders {
    if (_isSearching) {
      return _filteredOrders;
    }
    
    List<Order> result = List.from(_orders);
    if (_loadingOrder != null) {
      result.insert(0, _loadingOrder!);
    }
    return result;
  }

  Map<int, Order> get ordersMap => _ordersMap;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  bool get hasLoadingOrder => _loadingOrder != null;
  Order? get loadingOrder => _loadingOrder;

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
      _hasMoreData = response.length == _perPage; // ✅ Simple logic như Customer
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
        _hasMoreData = response.length == _perPage; // ✅ Simple logic như Customer
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
      clearSearch(); // ✅ Use clearSearch() instead
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
      
      // ✅ Cập nhật _ordersMap với search results để đồng bộ
      for (final order in searchResults) {
        _ordersMap[order.id] = order;
      }
      
      // ✅ Merge search results vào _orders để đồng bộ
      for (final searchOrder in searchResults) {
        final existingIndex = _orders.indexWhere((o) => o.id == searchOrder.id);
        if (existingIndex != -1) {
          // Update existing order với data mới
          _orders[existingIndex] = searchOrder;
        } else {
          // Thêm order mới và sort lại theo date
          _orders.add(searchOrder);
        }
      }
      
      // ✅ Sort lại _orders theo date_created descending
      _orders.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
      
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
    
    // ✅ Không cần reload API vì _orders đã được sync trong searchOrders()
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
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> customer,
    required String customerNote,
    required double taxFee,
  }) async {
    try {
      final updatedOrder = await OrderService.updateOrder(
        orderId: orderId,
        lineItems: lineItems,
        customer: customer,
        customerNote: customerNote,
        taxFee: taxFee,
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

  /// Tạo temporary loading order (tương tự ProductProvider)
  void addLoadingOrder({
    required String customerName,
    required String total,
    required int itemCount,
  }) {
    // Tạo fake line items để hiển thị đúng số lượng sản phẩm
    final fakeLineItems = List.generate(itemCount, (index) => OrderItem(
      id: index,
      name: 'Đang tải...',
      productId: 0,
      quantity: 1,
      price: 0.0,
      image: null,
      warehouse: '',
    ));

    _loadingOrder = Order(
      id: _loadingOrderTempId,
      status: 'pending', // Trạng thái đang tạo
      dateCreated: DateTime.now(),
      total: double.tryParse(total.replaceAll('zł', '').replaceAll(' ', '')) ?? 0.0,
      customerId: 0,
      billing: Billing(
        firstName: customerName,
        lastName: '',
        email: '',
        phone: '',
        address: '',
        nip: '',
      ),
      lineItems: fakeLineItems, // ✅ Fake items với đúng số lượng
      taxFee: '0.00',
      customerNote: '',
      number: 'Đang tạo...',
    );
    notifyListeners();
  }

  /// Thay thế loading order bằng real order
  void replaceLoadingOrderWithReal(Order realOrder) {
    if (_loadingOrder != null) {
      _loadingOrder = null;
      _orders.insert(0, realOrder);
      _ordersMap[realOrder.id] = realOrder;
      notifyListeners();
    }
  }

  /// Xóa loading order nếu có lỗi
  void removeLoadingOrder() {
    if (_loadingOrder != null) {
      _loadingOrder = null;
      notifyListeners();
    }
  }

  Future<Order?> createOrder({
    required List<Map<String, dynamic>> lineItems,
    required Map<String, dynamic> customer,
    required String customerNote,
    required double taxFee,
  }) async {
    try {
      final newOrder = await OrderService.createOrder(
        lineItems: lineItems,
        customer: customer,
        customerNote: customerNote,
        taxFee: taxFee,
      );
      
      if (newOrder != null) {
        // ✅ Thay thế loading order bằng real order
        replaceLoadingOrderWithReal(newOrder);
        return newOrder;
      } else {
        // ❌ Xóa loading order nếu lỗi
        removeLoadingOrder();
        return null;
      }
    } catch (e) {
      print('Error creating order: $e');
      // ❌ Xóa loading order nếu lỗi
      removeLoadingOrder();
      return null;
    }
  }
}