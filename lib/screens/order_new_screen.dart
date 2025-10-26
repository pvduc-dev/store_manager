import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/providers/order_provider.dart';
import 'package:store_manager/models/customer.dart';
import 'package:store_manager/widgets/molecule/customer_search_dialog.dart';
import 'package:store_manager/utils/currency_formatter.dart';
import 'package:store_manager/services/customer_service.dart';
import 'package:store_manager/widgets/atom/text_field.dart';
import 'package:store_manager/widgets/atom/text_area.dart';

enum CustomerMode { existing, newCustomer }

class OrderNewScreen extends StatefulWidget {
  const OrderNewScreen({super.key});

  @override
  State<OrderNewScreen> createState() => _OrderNewScreenState();
}

class _OrderNewScreenState extends State<OrderNewScreen> {
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

  // Tax rate
  double _taxRate = 1.23;

  // Customer selection
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Set default tax rate value
    _taxRateController.text = _taxRate.toStringAsFixed(2);
    
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
    _firstNameController.clear();
    _taxCodeController.clear();
    _address1Controller.clear();
    _phoneController.clear();
    _emailController.clear();
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

  Widget _buildCustomerInfoDisplay(String label, String value) {
    final hasValue = value.isNotEmpty;
    final displayText = hasValue ? value : 'Wyszukaj klienta...';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: hasValue ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasValue ? Colors.grey[300]! : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: hasValue ? Colors.grey[800] : Colors.grey[400],
              fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Informacje o zamówieniu'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            context.go('/cart');
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
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
                  _buildOrderSummary(cartProvider),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Container(
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
            child: _buildCheckoutButton(),
          );
        },
      ),
    );
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
            
            // Hiển thị tên khách hàng
            _buildCustomerInfoDisplay('Imię i nazwisko *', _selectedCustomer?.fullName ?? ''),
            const SizedBox(height: 16),
          ],

          // Tên khách hàng (chỉ hiện khi chế độ khách hàng mới)
          if (_customerMode == CustomerMode.newCustomer) ...[
            AppTextField(
              controller: _firstNameController,
              label: 'Imię i nazwisko *',
              enabled: _customerMode == CustomerMode.newCustomer,
              validator: (value) =>
                  value?.isEmpty == true ? 'Proszę podać imię i nazwisko' : null,
            ),
            const SizedBox(height: 16),
          ],

          // Hiển thị thông tin khách hàng cũ (luôn hiển thị kể cả khi chưa chọn)
          if (_customerMode == CustomerMode.existing) ...[
            _buildCustomerInfoDisplay('NIP (opcjonalnie)', _selectedCustomer?.nip ?? ''),
            const SizedBox(height: 16),
            _buildCustomerInfoDisplay('Adres *', _selectedCustomer?.address ?? ''),
            const SizedBox(height: 16),
            _buildCustomerInfoDisplay('Numer telefonu *', _selectedCustomer?.phone ?? ''),
            const SizedBox(height: 16),
            _buildCustomerInfoDisplay('Adres email *', _selectedCustomer?.email ?? ''),
          ],

          // Form fields cho khách hàng mới
          if (_customerMode == CustomerMode.newCustomer) ...[
            AppTextField(
              controller: _taxCodeController,
              label: 'NIP (opcjonalnie)',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _address1Controller,
              label: 'Adres *',
              validator: (value) =>
                  value?.isEmpty == true ? 'Proszę podać adres' : null,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _phoneController,
              label: 'Numer telefonu *',
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value?.isEmpty == true ? 'Proszę podać numer telefonu' : null,
            ),

            const SizedBox(height: 16),

            AppTextField(
              controller: _emailController,
              label: 'Adres email *',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty == true) return 'Proszę podać email';
                return null;
              },
            ),
          ],

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

  Widget _buildOrderSummary(CartProvider cartProvider) {
    final items = cartProvider.offlineItems;
    if (items.isEmpty) {
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
            'Koszyk jest pusty',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Net total (price before tax - Razem netto)
    double netTotal = 0;
    for (var item in items) {
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
          // Product List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              double price = double.tryParse(item.price) ?? 0;

              return Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Product Image
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image, color: Colors.grey),
                              ),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),

                    const SizedBox(width: 12),

                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'x ${item.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price
                    Text(
                      CurrencyFormatter.formatPLN(price * item.quantity),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Validation cho mode khách hàng cũ
          if (_customerMode == CustomerMode.existing && _selectedCustomer == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Proszę wybrać klienta'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          if (_formKey.currentState!.validate()) {
            _processCheckout();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Zamów',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
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

  void _processCheckout() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    final items = cartProvider.offlineItems;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Koszyk jest pusty!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Calculate totals for loading order
    double netTotal = 0;
    for (var item in items) {
      double price = double.tryParse(item.price) ?? 0;
      netTotal += price * item.quantity;
    }
    double bruttoTotal = netTotal * _taxRate;

    // Prepare customer name for loading order
    String customerName;
    if (_customerMode == CustomerMode.existing && _selectedCustomer != null) {
      customerName = _selectedCustomer!.fullName;
    } else {
      customerName = _firstNameController.text.trim();
    }

    // ✅ Tạo loading order ngay lập tức (không cần loading dialog)
    orderProvider.addLoadingOrder(
      customerName: customerName,
      total: bruttoTotal.toString(), // Pass as string for parsing
      itemCount: items.length,
    );

    // Navigate to orders screen ngay lập tức
    context.go('/orders');

    // ✅ Tạo order trong background (không block UI)
    _createOrderInBackground(cartProvider, orderProvider, items);
  }

  /// Tạo order trong background sau khi đã navigate
  Future<void> _createOrderInBackground(
    CartProvider cartProvider, 
    OrderProvider orderProvider, 
    List<dynamic> items
  ) async {
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
        
        print('📋 Creating new customer for order...');
        final customerData = _createCustomerDataFromForm();
        final newCustomer = await CustomerService.createCustomer(customerData);
        if (newCustomer != null) {
          print('✅ New customer created with ID: ${newCustomer.id}');
          _selectedCustomer = newCustomer;
        } else {
          print('❌ Failed to create customer, continuing with order...');
          // Continue without customer - order can still be created with billing info
        }
      }

      // Calculate net total (before tax) for order notes
      double netTotal = 0;
      for (var item in items) {
        double price = double.tryParse(item.price) ?? 0;
        netTotal += price * item.quantity;
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

      // Prepare line items for new API (simplified)
      final lineItems = <Map<String, dynamic>>[];
      for (var item in items) {
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

      // Create order with new API structure
      final order = await orderProvider.createOrder(
        lineItems: lineItems,
        customer: customerData,
        customerNote: customerNote,
        taxFee: taxAmount,
      );

      if (order != null) {
        // Clear cart after successful order
        await cartProvider.clearCart();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zamówienie zostało złożone pomyślnie! Numer zamówienia: ${order.number}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // ❌ Xóa loading order và show error
        orderProvider.removeLoadingOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas tworzenia zamówienia. Spróbuj ponownie!'),
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
