import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:store_manager/providers/order_provider.dart';

import 'package:store_manager/models/customer.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/models/offline_cart.dart';
import 'package:store_manager/models/product.dart';
import 'package:store_manager/services/product_service.dart';
import 'package:store_manager/widgets/molecule/customer_search_box.dart';
import 'package:store_manager/widgets/molecule/offline_cart_item.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class OrderEditScreen extends StatefulWidget {
  final int orderId;
  
  const OrderEditScreen({super.key, required this.orderId});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerSearchController = CustomerSearchController();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _taxCodeController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _noteController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _taxRateFocusNode = FocusNode();
  final _searchController = TextEditingController();

  // Payment method
  String _paymentMethod = 'Płatność przy odbiorze';

  // Tax rate
  double _taxRate = 1.23;
  int? _existingTaxFeeLineId; // Track existing tax fee line ID for updates

  // Customer selection
  Customer? _selectedCustomer;

  // Order data
  Order? _currentOrder;
  bool _isLoadingOrder = true;
  
  // Editable order items (converted from OrderItem to OfflineCartItem for editing)
  List<OfflineCartItem> _editableItems = [];
  
  // Product search state
  List<Product> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
    
    // Add focus listener for tax rate field
    _taxRateFocusNode.addListener(_onTaxRateFocusChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _taxCodeController.dispose();
    _address1Controller.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _noteController.dispose();
    _taxRateController.dispose();
    _taxRateFocusNode.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onTaxRateFocusChanged() {
    if (!_taxRateFocusNode.hasFocus) {
      // User has unfocused from tax rate field
      _validateAndUpdateTaxRate();
    }
  }

  void _validateAndUpdateTaxRate() {
    final text = _taxRateController.text.trim();
    final value = double.tryParse(text);
    
    if (value == null || value <= 0) {
      // Invalid value, reset to default
      setState(() {
        _taxRate = 1.23;
        _taxRateController.text = _taxRate.toStringAsFixed(2);
      });
    } else {
      // Valid value, update tax rate
      setState(() {
        _taxRate = value;
      });
    }
  }
  
  // Convert OrderItem to OfflineCartItem for editing
  OfflineCartItem _orderItemToCartItem(OrderItem orderItem) {
    return OfflineCartItem(
      productId: orderItem.productId,
      name: orderItem.name,
      price: orderItem.price.toStringAsFixed(2),
      quantity: orderItem.quantity,
      imageUrl: orderItem.image?.src,
      addedAt: DateTime.now(), // Use current time since original addedAt is not available
      lineItemId: orderItem.id, // Store WooCommerce line item ID for updating
      isDeleted: false, // Existing items are not deleted by default
    );
  }
  
  // Add new product to editable items
  void _addProductToOrder(int productId, String name, String price, String? imageUrl) {
    setState(() {
      final existingIndex = _editableItems.indexWhere((item) => item.productId == productId);
      if (existingIndex >= 0) {
        final existingItem = _editableItems[existingIndex];
        if (existingItem.isDeleted) {
          // Item was deleted, restore it with quantity 1
          _editableItems[existingIndex] = existingItem.copyWith(
            quantity: 1,
            isDeleted: false,
          );
        } else {
          // Product already exists and not deleted, increase quantity
          _editableItems[existingIndex] = existingItem.copyWith(
            quantity: existingItem.quantity + 1,
          );
        }
      } else {
        // Add new product (no lineItemId since it's new)
        _editableItems.add(OfflineCartItem(
          productId: productId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          addedAt: DateTime.now(),
          lineItemId: null, // New products don't have WooCommerce line item ID yet
          isDeleted: false,
        ));
      }
    });
  }
  
  // Update item quantity
  void _updateItemQuantity(int productId, int quantity) {
    setState(() {
      final index = _editableItems.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        if (quantity <= 0) {
          // Mark as deleted instead of removing
          _editableItems[index] = _editableItems[index].copyWith(isDeleted: true);
        } else {
          _editableItems[index] = _editableItems[index].copyWith(
            quantity: quantity,
            isDeleted: false, // Undelete if user is editing quantity
          );
        }
      }
    });
  }
  
  // Update item price
  void _updateItemPrice(int productId, String price) {
    setState(() {
      final index = _editableItems.indexWhere((item) => item.productId == productId);
      if (index >= 0) {
        _editableItems[index] = _editableItems[index].copyWith(
          price: price,
          isDeleted: false, // Undelete if user is editing price
        );
      }
    });
  }
  
  // Mark item as deleted (for WooCommerce API)
  void _removeItem(int productId) {
    setState(() {
      final index = _editableItems.indexWhere((item) => item.productId == productId);
      if (index != -1) {
        _editableItems[index] = _editableItems[index].copyWith(isDeleted: true);
      }
    });
  }
  
  // Handle product search with debounce
  void _handleProductSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults.clear();
      });
      return;
    }
    
    // Cancel previous debounce timer
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce?.cancel();
    }
    
    // Set up new debounce timer
    _searchDebounce = Timer(const Duration(milliseconds: 1000), () {
      _performProductSearch(query);
    });
  }
  
  // Perform actual product search
  Future<void> _performProductSearch(String query) async {
    setState(() {
      _isSearching = true;
      _showSearchResults = true;
    });
    
    try {
      final results = await ProductService.searchProducts(query, perPage: 10);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      print('Error searching products: $e');
    }
  }
  
  // Add product from search results
  void _addProductFromSearch(Product product) {
    _addProductToOrder(
      product.id,
      product.name,
      '0.00', // Default price - will be edited by user
      product.images.isNotEmpty ? product.images.first.src : null,
    );
    
    // Clear search field and results after adding
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResults.clear();
    });
  }

  Future<void> _loadOrderData() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = await orderProvider.loadOrderDetail(widget.orderId);
    
    if (order != null) {
      setState(() {
        _currentOrder = order;
        _isLoadingOrder = false;
        
        // Pre-fill form với dữ liệu order hiện tại
        _fillOrderInfo(order);
      });
    } else {
      setState(() {
        _isLoadingOrder = false;
      });
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie można załadować informacji o zamówieniu!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOrder) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Edytuj zamówienie'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentOrder == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Edytuj zamówienie'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Nie znaleziono zamówienia',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Edytuj zamówienie #${_currentOrder!.number}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 100, // Padding để tránh button
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Information Form
              _buildCustomerForm(),

              const SizedBox(height: 32),

              // Order Summary
              _buildOrderSummary(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: _buildUpdateButton(),
      ),
    );
  }

  void _fillOrderInfo(Order order) {
    // Fill customer information from order billing
    final fullName = '${order.billing.firstName} ${order.billing.lastName}'.trim();
    
    // Set cả hai controller để đảm bảo tên khách hàng hiển thị đúng
    _firstNameController.text = fullName;
    _customerSearchController.setText(fullName);
    
    _taxCodeController.text = order.billing.company;
    _address1Controller.text = order.billing.address1;
    _cityController.text = order.billing.city;
    _phoneController.text = order.billing.phone;
    _emailController.text = order.billing.email;
    
    // Fill payment method
    _paymentMethod = order.paymentMethodTitle;
    
    // Extract tax info from customer note if available
    _noteController.text = _extractCleanNote(order.customerNote);
    
    // Try to extract tax rate from existing fee_lines if available
    if (order.feeLines.isNotEmpty) {
      for (final feeLine in order.feeLines) {
        if (feeLine.name.contains('Tax')) {
          // Extract tax rate from fee line name like "Tax (1.23x)"
          RegExp taxRateRegex = RegExp(r'Tax \((\d+\.?\d*)x\)');
          Match? match = taxRateRegex.firstMatch(feeLine.name);
          if (match != null) {
            _taxRate = double.tryParse(match.group(1) ?? '1.23') ?? 1.23;
            _existingTaxFeeLineId = feeLine.id; // Store existing tax fee line ID
            break;
          }
        }
      }
    }
    _taxRateController.text = _taxRate.toStringAsFixed(2);
    
    // Convert order items to editable items
    _editableItems = order.lineItems.map((orderItem) => _orderItemToCartItem(orderItem)).toList();
  }

  String _extractCleanNote(String customerNote) {
    // Remove tax information from customer note to show only the original note
    final lines = customerNote.split('\n');
    final cleanLines = <String>[];
    
    for (final line in lines) {
      if (!line.startsWith('Tax rate:') && 
          !line.startsWith('Customer ID:')) {
        cleanLines.add(line);
      }
    }
    
    return cleanLines.join('\n').trim();
  }

  void _fillCustomerInfo(Customer customer) {
    setState(() {
      _selectedCustomer = customer;

      // Fill customer information into form fields
      _customerSearchController.setText(customer.fullName);
      _taxCodeController.text = customer.billingCompany;
      _address1Controller.text = customer.billingAddress;
      _phoneController.text = customer.billingPhone;
      _emailController.text = customer.email;
    });
  }

  Widget _buildCustomerForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Name with Search
          CustomerSearchBox(
            controller: _firstNameController,
            searchController: _customerSearchController,
            onCustomerSelected: (Customer customer) {
              _fillCustomerInfo(customer);
            },
            validator: (value) =>
                value?.isEmpty == true ? 'Proszę podać nazwę' : null,
          ),

          const SizedBox(height: 16),

          // Tax Code (NIP)
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _taxCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'NIP (opcjonalnie)',
                hintText: 'Wprowadź numer NIP',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Address
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _address1Controller,
              decoration: const InputDecoration(
                labelText: 'Adres *',
                hintText: 'Wprowadź adres',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Proszę podać adres' : null,
            ),
          ),

          const SizedBox(height: 16),

          // Phone
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numer telefonu *',
                hintText: 'Wprowadź numer telefonu',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Proszę podać numer telefonu' : null,
            ),
          ),

          const SizedBox(height: 16),

          // Email
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Adres email *',
                hintText: 'Wprowadź email',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value?.isEmpty == true) return 'Proszę podać email';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value!)) {
                  return 'Nieprawidłowy adres email';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // Order Notes
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Uwagi do zamówienia (opcjonalnie)',
                hintText: 'Uwagi dotyczące zamówienia',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                alignLabelWithHint: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Column(
      children: [
        // Custom product search box
        _buildProductSearchBox(),
        
        const SizedBox(height: 16),
        
        // Order items
        _buildOrderItems(),
      ],
    );
  }
  
  Widget _buildProductSearchBox() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Wyszukaj produkty do dodania do zamówienia...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _showSearchResults = false;
                          _searchResults.clear();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                    )
                  : null,
            ),
            onChanged: _handleProductSearch,
          ),
        ),
        
        // Search results
        if (_showSearchResults) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isSearching
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _searchResults.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nie znaleziono produktów',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final product = _searchResults[index];
                      return ListTile(
                        onTap: () => _addProductFromSearch(product),
                        leading: product.images.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product.images.first.src ?? '',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.image, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.image, color: Colors.grey),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'ID: ${product.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: const Icon(Icons.add, color: Colors.green),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildOrderItems() {
    if (_editableItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Zamówienie nie zawiera produktów\nUżyj paska wyszukiwania, aby dodać produkty',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Net total (price before tax - Razem netto) - only non-deleted items
    double netTotal = 0;
    for (var item in _editableItems.where((item) => !item.isDeleted)) {
      double price = double.tryParse(item.price) ?? 0;
      netTotal += price * item.quantity;
    }

    // Calculate gross price with tax (Suma Brutto)
    double bruttoTotal = netTotal * _taxRate;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header thông tin tổng quan
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_editableItems.length} pozycji | ${_editableItems.fold(0, (sum, item) => sum + item.quantity)} produktów',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          
          // Editable Product List (show only non-deleted items)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _editableItems.where((item) => !item.isDeleted).length,
            itemBuilder: (context, index) {
              final nonDeletedItems = _editableItems.where((item) => !item.isDeleted).toList();
              final item = nonDeletedItems[index];
              
              return OfflineCartItemWidget(
                item: item,
                onQuantityChanged: (quantity) {
                  _updateItemQuantity(item.productId, quantity);
                },
                onPriceChanged: (price) {
                  _updateItemPrice(item.productId, price);
                },
                onRemove: () {
                  _removeItem(item.productId);
                },
              );
            },
          ),

          const Divider(height: 1),

          // Summary Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Net total before tax
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Suma:', style: TextStyle(fontSize: 16)),
                    Text(
                      CurrencyFormatter.formatPLN(netTotal),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Razem (Netto):',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      CurrencyFormatter.formatPLN(netTotal),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Tax rate input row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Współczynnik podatkowy:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _taxRateController,
                        focusNode: _taxRateFocusNode,
                        decoration: const InputDecoration(
                          hintText: '1.23',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Suma (Brutto):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPLN(bruttoTotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Billing Address
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adres płatności',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_firstNameController.text.isNotEmpty)
                        Text(
                          _firstNameController.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (_taxCodeController.text.isNotEmpty)
                        Text(
                          _taxCodeController.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (_address1Controller.text.isNotEmpty)
                        Text(
                          _address1Controller.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                      if (_phoneController.text.isNotEmpty)
                        Text(
                          _phoneController.text,
                          style: const TextStyle(fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _processUpdate();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'ZAKTUALIZUJ ZAMÓWIENIE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _processUpdate() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (_editableItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Zamówienie nie zawiera produktów!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Aktualizowanie zamówienia...'),
          ],
        ),
      ),
    );

    try {
      // Calculate net total (before tax) from editable items - only non-deleted items
      double netTotal = 0;
      for (var item in _editableItems.where((item) => !item.isDeleted)) {
        double price = double.tryParse(item.price) ?? 0;
        netTotal += price * item.quantity;
      }
      
      // Calculate brutto total (after tax)
      double bruttoTotal = netTotal * _taxRate;

      // Prepare billing info
      final fullName = _firstNameController.text.split(' ');
      final firstName = fullName.isNotEmpty ? fullName.first : '';
      final lastName = fullName.length > 1 ? fullName.sublist(1).join(' ') : '';

      final billingInfo = {
        'first_name': firstName,
        'last_name': lastName,
        'company': _taxCodeController.text,
        'address_1': _address1Controller.text,
        'address_2': '',
        'city': _cityController.text,
        'state': '',
        'postcode': '',
        'email': _emailController.text,
        'phone': _phoneController.text,
      };

      // Prepare line items from editable items
      // WooCommerce logic:
      // - Items with 'id' and quantity > 0: Will be updated
      // - Items with 'id' and quantity = 0: Will be deleted
      // - Items without 'id' and quantity > 0: Will be created as new
      final lineItems = _editableItems.map((item) {
        double price = double.tryParse(item.price) ?? 0;
        int quantity = item.isDeleted ? 0 : item.quantity; // Set quantity = 0 for deleted items
        
        final lineItem = <String, dynamic>{
          'product_id': item.productId,
          'quantity': quantity,
          'total': (price * quantity).toStringAsFixed(2),
          'subtotal': (price * quantity).toStringAsFixed(2), // Subtotal equals total
        };
        
        // Include line item ID if this is an existing item (for update/delete)
        if (item.lineItemId != null) {
          lineItem['id'] = item.lineItemId!;
        }
        // If lineItemId is null, this is a new item and WooCommerce will create it
        
        return lineItem;
      }).toList();

      // Calculate tax amount 
      double taxAmount = bruttoTotal - netTotal;

      // Prepare customer note (only user's note, no tax info)
      String customerNote = _noteController.text.trim();
      if (_selectedCustomer != null && customerNote.isNotEmpty) {
        customerNote += '\nCustomer ID: ${_selectedCustomer!.id}';
      } else if (_selectedCustomer != null) {
        customerNote = 'Customer ID: ${_selectedCustomer!.id}';
      }
      
      // Prepare tax fee lines
      // WooCommerce fee_lines logic:
      // - Fee lines with 'id': Will be updated
      // - Fee lines without 'id': Will be created as new
      final taxFeeLine = <String, dynamic>{
        'name': 'Tax (${_taxRate.toStringAsFixed(2)}x)',
        'total': taxAmount.toStringAsFixed(2),
      };
      
      // Include existing tax fee line ID if updating existing fee line
      if (_existingTaxFeeLineId != null) {
        taxFeeLine['id'] = _existingTaxFeeLineId!;
      }
      
      final taxFeeLines = [taxFeeLine];

      // Update order
      final updatedOrder = await orderProvider.updateOrder(
        orderId: widget.orderId,
        billingInfo: billingInfo,
        lineItems: lineItems,
        paymentMethod: 'cod',
        paymentMethodTitle: _paymentMethod,
        customerNote: customerNote,
        feeLines: taxFeeLines,
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (updatedOrder != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zamówienie zostało pomyślnie zaktualizowane! Numer zamówienia: ${updatedOrder.number}'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        context.pop();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas aktualizacji zamówienia. Spróbuj ponownie!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}