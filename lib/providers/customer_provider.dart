import 'package:flutter/material.dart';
import 'package:store_manager/models/customer.dart';
import 'package:store_manager/services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  List<Customer> _customers = [];
  Map<int, Customer> _customersMap = {};
  bool _isLoading = false;
  String _searchQuery = '';

  List<Customer> get customers => _customers;
  Map<int, Customer> get customersMap => _customersMap;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  // Lấy danh sách customers được lọc theo tìm kiếm
  List<Customer> get filteredCustomers {
    if (_searchQuery.isEmpty) {
      return _customers;
    }
    return _customers.where((customer) {
      final query = _searchQuery.toLowerCase();
      return customer.fullName.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.billingCompany.toLowerCase().contains(query) ||
          customer.billingPhone.contains(query);
    }).toList();
  }

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await CustomerService.getCustomers();
      _customers = response;
      _customersMap = Map.fromEntries(
        response.map((customer) => MapEntry(customer.id, customer)),
      );
    } catch (e) {
      print('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Customer?> loadCustomerById(int customerId) async {
    try {
      final customer = await CustomerService.getCustomerById(customerId);
      if (customer != null) {
        _customersMap[customer.id] = customer;
        
        // Cập nhật trong danh sách nếu đã tồn tại
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = customer;
        } else {
          _customers.add(customer);
        }
        
        notifyListeners();
      }
      return customer;
    } catch (e) {
      print('Error loading customer by id: $e');
      return null;
    }
  }

  Future<void> updateCustomer(Map<String, dynamic> data) async {
    try {
      final customer = await CustomerService.updateCustomer(data);
      if (customer != null) {
        final index = _customers.indexWhere((c) => c.id == customer.id);
        if (index != -1) {
          _customers[index] = customer;
          _customersMap[customer.id] = customer;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating customer: $e');
    }
  }

  Future<void> addCustomer(Map<String, dynamic> data) async {
    try {
      final customer = await CustomerService.createCustomer(data);
      if (customer != null) {
        _customers.insert(0, customer);
        _customersMap[customer.id] = customer;
        notifyListeners();
      }
    } catch (e) {
      print('Error adding customer: $e');
    }
  }

  Future<void> deleteCustomer(int customerId) async {
    try {
      final success = await CustomerService.deleteCustomer(customerId);
      if (success) {
        _customers.removeWhere((customer) => customer.id == customerId);
        _customersMap.remove(customerId);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting customer: $e');
    }
  }

  Future<void> searchCustomers(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await CustomerService.searchCustomers(query);
      _customers = response;
      _customersMap = Map.fromEntries(
        response.map((customer) => MapEntry(customer.id, customer)),
      );
    } catch (e) {
      print('Error searching customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  Customer? getCustomerById(int id) {
    return _customersMap[id];
  }

  // Lấy top customers theo số lượng đơn hàng (cần thêm logic nếu có dữ liệu)
  List<Customer> getTopCustomers({int limit = 10}) {
    return _customers
        .where((customer) => customer.isPayingCustomer)
        .take(limit)
        .toList();
  }

  // Thống kê số lượng customers
  int get totalCustomers => _customers.length;
  int get payingCustomers => _customers.where((c) => c.isPayingCustomer).length;
  int get newCustomers => _customers.where((c) => 
      DateTime.parse(c.dateCreated).isAfter(
        DateTime.now().subtract(Duration(days: 30))
      )
    ).length;
}