import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:store_manager/models/customer.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/models/offline_cart.dart';
import 'package:store_manager/models/product.dart' as product_models;
import 'package:store_manager/providers/order_provider.dart';
import 'package:store_manager/services/product_service.dart';
import 'package:store_manager/services/customer_service.dart';
import 'package:store_manager/widgets/molecule/customer_search_dialog.dart';
import 'package:store_manager/widgets/molecule/offline_cart_item.dart';
import 'package:store_manager/widgets/atom/text_field.dart';
import 'package:store_manager/widgets/atom/text_area.dart';
import 'package:store_manager/utils/currency_formatter.dart';

enum CustomerMode { existing, newCustomer }

class OrderEditScreen extends StatefulWidget {
  final String orderId;
  
  const OrderEditScreen({super.key, required this.orderId});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final _formKey = GlobalKey<FormState>();

  // Customer mode selection
  CustomerMode _customerMode = CustomerMode.existing;

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

  // Payment method - removed as not used in simplified model

  // Tax rate
  double _taxRate = 1.23;

  // Customer selection
  Customer? _selectedCustomer;

  // Order data - now passed from parent screen
  
  // Editable order items (converted from OrderItem to OfflineCartItem for editing)
  List<OfflineCartItem> _editableItems = [];
  
  // Product search state
  List<product_models.Product> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    
    // Add focus listener for tax rate field
    _taxRateFocusNode.addListener(_onTaxRateFocusChanged);
    
    // Initialize form with order data after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeOrderData();
    });
  }

  void _initializeOrderData() {
    final orderId = int.tryParse(widget.orderId);
    if (orderId == null) return;
    
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final order = orderProvider.getOrderById(orderId);
    
    if (order != null) {
      _fillOrderInfo(order);
    }
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

  void _clearCustomerForm() {
    _selectedCustomer = null;
    // Don't clear form fields when switching modes
    // Keep current data so user can see what was there
  }

  Widget _buildCustomerModeSelector() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 0),
      margin: const EdgeInsets.only(bottom: 16),
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
          const Text(
            'Typ klienta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCustomerModeOption(
                  title: 'Klient istniejący',
                  value: CustomerMode.existing,
                  isSelected: _customerMode == CustomerMode.existing,
                  onTap: () {
                    setState(() {
                      _customerMode = CustomerMode.existing;
                      _clearCustomerForm();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCustomerModeOption(
                  title: 'Nowy klient',
                  value: CustomerMode.newCustomer,
                  isSelected: _customerMode == CustomerMode.newCustomer,
                  onTap: () {
                    setState(() {
                      _customerMode = CustomerMode.newCustomer;
                      _clearCustomerForm();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerModeOption({
    required String title,
    required CustomerMode value,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final primaryColor = Theme.of(context).colorScheme.primary;
        
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? primaryColor : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? primaryColor : Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget _buildCustomerSearchButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final result = await showDialog<Customer>(
              useSafeArea: false,
              context: context,
              builder: (context) => const CustomerSearchDialog(),
            );
            
            if (result != null) {
              _fillCustomerInfo(result);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[500]!,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Wyszukaj klienta...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                Icon(
                  _selectedCustomer != null ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: _selectedCustomer != null 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  // Convert OrderItem to OfflineCartItem for editing
  OfflineCartItem _orderItemToCartItem(OrderItem orderItem) {
    // Note: OrderItem.price is already total price from API
    // For editing, we need to calculate unit price
    double unitPrice = orderItem.price;
    if (orderItem.quantity > 0) {
      unitPrice = orderItem.price / orderItem.quantity;
    }
    
    return OfflineCartItem(
      productId: orderItem.productId,
      name: orderItem.name,
      price: unitPrice.toStringAsFixed(2), // Store unit price for editing
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
    }
  }
  
  // Add product from search results
  void _addProductFromSearch(product_models.Product product) {
    _addProductToOrder(
      product.id,
      product.name,
      '0.00', // Default price - will be edited by user
      product.image?.src,
    );
    
    // Clear search field and results after adding
    _searchController.clear();
    setState(() {
      _showSearchResults = false;
      _searchResults.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Edytuj zamówienie #${widget.orderId}'),
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
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
          // Re-initialize data if needed
          final orderId = int.tryParse(widget.orderId);
          if (orderId != null && _editableItems.isEmpty) {
            final order = orderProvider.getOrderById(orderId);
            if (order != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fillOrderInfo(order);
              });
            }
          }
          
          return SingleChildScrollView(
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
                  // Customer Mode Selector
                  _buildCustomerModeSelector(),
                  
                  // Customer Information Form
                  _buildCustomerForm(),

                  const SizedBox(height: 32),

                  // Order Summary
                  _buildOrderSummary(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
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
    // Fill customer information from order billing (no API calls)
    final fullName = '${order.billing.firstName} ${order.billing.lastName}'.trim();
    
    // Set customer mode based on whether customer ID exists (non-zero means existing customer)
    _customerMode = order.customerId > 0 ? CustomerMode.existing : CustomerMode.newCustomer;
    
    // Always use billing data (no API calls to load customer)
    _firstNameController.text = fullName;
    _taxCodeController.text = order.billing.nip;
    _address1Controller.text = order.billing.address;
    _phoneController.text = order.billing.phone;
    _emailController.text = order.billing.email;
    
    _cityController.text = ''; // No city field in new model
    
    // Payment method - not used in simplified model
    
    // Extract tax info from customer note if available
    _noteController.text = _extractCleanNote(order.customerNote);
    
    // Try to extract tax rate from tax_fee field
    if (order.taxFee != null && order.taxFee!.isNotEmpty) {
      final taxFeeAmount = double.tryParse(order.taxFee!) ?? 0.0;
      if (taxFeeAmount > 0) {
        // Calculate tax rate from tax fee amount and total
        final netTotal = order.total - taxFeeAmount;
        if (netTotal > 0) {
          _taxRate = order.total / netTotal;
        }
      }
    } else {
      // If no tax fee, calculate from line items to match original total
      double calculatedNetTotal = 0;
      for (var item in order.lineItems) {
        double unitPrice = item.price / item.quantity;
        calculatedNetTotal += unitPrice * item.quantity;
      }
      
      if (calculatedNetTotal > 0 && order.total > 0) {
        _taxRate = order.total / calculatedNetTotal;
      }
    }
    _taxRateController.text = _taxRate.toStringAsFixed(2);
    
    // Convert order items to editable items
    setState(() {
      _editableItems = order.lineItems.map((orderItem) => _orderItemToCartItem(orderItem)).toList();
    });
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

      // Fill customer information into form fields (for new customer mode or billing)
      if (_customerMode == CustomerMode.newCustomer) {
        _firstNameController.text = customer.fullName;
      }
      _taxCodeController.text = customer.nip;
      _address1Controller.text = customer.address;
      _phoneController.text = customer.phone;
      _emailController.text = customer.email;
    });
  }

  // Helper method to create customer data from form fields
  Map<String, dynamic> _createCustomerDataFromForm() {
    final fullName = _firstNameController.text.split(' ');
    final firstName = fullName.isNotEmpty ? fullName.first : '';
    final lastName = fullName.length > 1 ? fullName.sublist(1).join(' ') : '';
    
    final email = _emailController.text.trim();

    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': 'customer@113', // Default password for new customers
      'billing': {
        'first_name': firstName,
        'last_name': lastName,
        'company': _taxCodeController.text,
        'address_1': _address1Controller.text,
        'address_2': '',
        'city': _cityController.text,
        'state': '',
        'postcode': '',
        'country': 'PL',
        'email': email,
        'phone': _phoneController.text,
      },
      'shipping': {
        'first_name': firstName,
        'last_name': lastName,
        'company': _taxCodeController.text,
        'address_1': _address1Controller.text,
        'address_2': '',
        'city': _cityController.text,
        'state': '',
        'postcode': '',
        'country': 'PL',
        'phone': _phoneController.text,
      },
    };
  }

  // Helper method to validate email format
  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // Basic email validation
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // Helper method to check if we should create a new customer
  bool _shouldCreateNewCustomer() {
    // Chỉ tạo customer mới khi chọn chế độ khách hàng mới
    if (_customerMode == CustomerMode.existing) return false;
    if (_selectedCustomer != null) return false;
    
    // Check if we have required fields
    final hasName = _firstNameController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty;
    final hasPhone = _phoneController.text.trim().isNotEmpty;
    
    return hasName && hasEmail && hasPhone; // Need name, email and phone
  }

  Widget _buildCustomerForm() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
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
          const Text(
            'Informacje o kliencie',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Hiển thị search button chỉ khi chế độ khách hàng cũ
          if (_customerMode == CustomerMode.existing) ...[
            _buildCustomerSearchButton(),
            const SizedBox(height: 16),
          ],

          // Tên khách hàng (hiển thị cho cả hai mode)
          AppTextField(
            controller: _firstNameController,
            label: 'Imię i nazwisko *',
            enabled: _customerMode == CustomerMode.newCustomer,
            validator: _customerMode == CustomerMode.newCustomer 
                ? (value) => value?.isEmpty == true ? 'Proszę podać imię i nazwisko' : null
                : null,
          ),
          const SizedBox(height: 16),

          // Hiển thị form fields cho cả existing và new customer
          // NIP field
          AppTextField(
            controller: _taxCodeController,
            label: 'NIP (opcjonalnie)',
            keyboardType: TextInputType.number,
            enabled: _customerMode == CustomerMode.newCustomer,
          ),
          const SizedBox(height: 16),

          // Address field
          AppTextField(
            controller: _address1Controller,
            label: 'Adres *',
            validator: _customerMode == CustomerMode.newCustomer 
                ? (value) => value?.isEmpty == true ? 'Proszę podać adres' : null
                : null,
            enabled: _customerMode == CustomerMode.newCustomer,
          ),
          const SizedBox(height: 16),

          // Phone field
          AppTextField(
            controller: _phoneController,
            label: 'Numer telefonu *',
            keyboardType: TextInputType.phone,
            validator: _customerMode == CustomerMode.newCustomer 
                ? (value) => value?.isEmpty == true ? 'Proszę podać numer telefonu' : null
                : null,
            enabled: _customerMode == CustomerMode.newCustomer,
          ),
          const SizedBox(height: 16),

          // Email field
          AppTextField(
            controller: _emailController,
            label: 'Adres email *',
            keyboardType: TextInputType.emailAddress,
            validator: _customerMode == CustomerMode.newCustomer 
                ? (value) {
                    if (value?.isEmpty == true) return 'Proszę podać email';
                    return null;
                  }
                : null,
            enabled: _customerMode == CustomerMode.newCustomer,
          ),


          const SizedBox(height: 16),

          // Order Notes (luôn enabled)
          AppTextArea(
            controller: _noteController,
            label: 'Uwagi do zamówienia (opcjonalnie)',
            maxLines: 3,
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
                        leading: product.image?.src != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  product.image!.src!,
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
      double unitPrice = double.tryParse(item.price) ?? 0;
      netTotal += unitPrice * item.quantity;
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
                    AppTextField(
                      controller: _taxRateController,
                      focusNode: _taxRateFocusNode,
                      label: '',
                      isCompact: true,
                      width: 80,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
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
                      // Hiển thị thông tin billing dựa trên customer mode
                      if (_customerMode == CustomerMode.existing && _selectedCustomer != null) ...[
                        if (_selectedCustomer!.fullName.isNotEmpty)
                          Text(
                            _selectedCustomer!.fullName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (_selectedCustomer!.nip.isNotEmpty)
                          Text(
                            _selectedCustomer!.nip,
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (_selectedCustomer!.address.isNotEmpty)
                          Text(
                            _selectedCustomer!.address,
                            style: const TextStyle(fontSize: 14),
                          ),
                        if (_selectedCustomer!.phone.isNotEmpty)
                          Text(
                            _selectedCustomer!.phone,
                            style: const TextStyle(fontSize: 14),
                          ),
                      ] else ...[
                        // Hiển thị từ form fields cho new customer
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
          // Validation - check if we have customer information in form fields
          final hasCustomerInfo = _firstNameController.text.trim().isNotEmpty ||
                                 _emailController.text.trim().isNotEmpty ||
                                 _phoneController.text.trim().isNotEmpty;
          
          if (!hasCustomerInfo) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proszę podać informacje o kliencie'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
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

    // Calculate totals for loading order
    double netTotal = 0;
    for (var item in _editableItems.where((item) => !item.isDeleted)) {
      double unitPrice = double.tryParse(item.price) ?? 0;
      netTotal += unitPrice * item.quantity;
    }
    double bruttoTotal = netTotal * _taxRate;

    // Prepare customer name for loading order
    String customerName = _firstNameController.text.trim();

    // ✅ Tạo loading order ngay lập tức (không cần loading dialog)
    orderProvider.addLoadingOrder(
      customerName: customerName,
      total: bruttoTotal.toString(),
      itemCount: _editableItems.where((item) => !item.isDeleted).length,
    );

    // Navigate to orders screen ngay lập tức
    context.go('/orders');

    // ✅ Update order trong background (không block UI)
    _updateOrderInBackground(orderProvider);
  }

  /// Update order trong background sau khi đã navigate
  Future<void> _updateOrderInBackground(OrderProvider orderProvider) async {
    try {
      // Create customer if needed
      if (_shouldCreateNewCustomer()) {
        // Validate email before creating customer
        final email = _emailController.text.trim();
        if (!_isValidEmail(email)) {
          // ❌ Xóa loading order và show error
          orderProvider.removeLoadingOrder();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email không hợp lệ! Vui lòng nhập email đúng định dạng.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        final customerData = _createCustomerDataFromForm();
        final newCustomer = await CustomerService.createCustomer(customerData);
        if (newCustomer != null) {
          _selectedCustomer = newCustomer;
        }
        // Continue without customer - order can still be updated with billing info
      }

      // Calculate net total (before tax) for order notes
      double netTotal = 0;
      for (var item in _editableItems.where((item) => !item.isDeleted)) {
        double unitPrice = double.tryParse(item.price) ?? 0;
        netTotal += unitPrice * item.quantity;
      }
      
      // Calculate brutto total (after tax)
      double bruttoTotal = netTotal * _taxRate;

      // Prepare billing info
      String firstName, lastName, email, phone, address, company;
      
      if (_customerMode == CustomerMode.existing && _selectedCustomer != null) {
        // Use selected customer data
        final fullName = _selectedCustomer!.fullName.split(' ');
        firstName = fullName.isNotEmpty ? fullName.first : '';
        lastName = fullName.length > 1 ? fullName.sublist(1).join(' ') : '';
        email = _selectedCustomer!.email;
        phone = _selectedCustomer!.phone;
        address = _selectedCustomer!.address;
        company = _selectedCustomer!.nip;
      } else {
        // Use form data for new customer
        final fullName = _firstNameController.text.split(' ');
        firstName = fullName.isNotEmpty ? fullName.first : '';
        lastName = fullName.length > 1 ? fullName.sublist(1).join(' ') : '';
        email = _emailController.text;
        phone = _phoneController.text;
        address = _address1Controller.text;
        company = _taxCodeController.text;
      }

      // Prepare line items for new API format
      final lineItems = <Map<String, dynamic>>[];
      for (var item in _editableItems.where((item) => !item.isDeleted)) {
        double basePrice = double.tryParse(item.price) ?? 0;
        
        lineItems.add({
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price': basePrice,
        });
      }

      // Calculate tax amount 
      double taxAmount = bruttoTotal - netTotal;

      // Prepare customer data for new API format
      final customerData = {
        'first_name': '$firstName $lastName'.trim(),
        'last_name': lastName,
        'email': email,
        'address': address,
        'nip': company,
        'phone': phone,
      };

      // Prepare customer note
      String customerNote = _noteController.text.trim();
      if (_selectedCustomer != null && customerNote.isNotEmpty) {
        customerNote += '\nCustomer ID: ${_selectedCustomer!.id}';
      } else if (_selectedCustomer != null) {
        customerNote = 'Customer ID: ${_selectedCustomer!.id}';
      }

      // Update order with new API structure
      final order = await orderProvider.updateOrder(
        orderId: int.parse(widget.orderId),
        lineItems: lineItems,
        customer: customerData,
        customerNote: customerNote,
        taxFee: taxAmount,
      );

      if (order != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zamówienie zostało zaktualizowane pomyślnie! Numer zamówienia: ${order.number}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ❌ Xóa loading order và show error
        orderProvider.removeLoadingOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas aktualizacji zamówienia. Spróbuj ponownie!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ❌ Xóa loading order và show error
      orderProvider.removeLoadingOrder();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}