import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/providers/order_provider.dart';
import 'package:store_manager/models/customer.dart';
import 'package:store_manager/widgets/molecule/customer_search_box.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class OrderNewScreen extends StatefulWidget {
  const OrderNewScreen({super.key});

  @override
  State<OrderNewScreen> createState() => _OrderNewScreenState();
}

class _OrderNewScreenState extends State<OrderNewScreen> {
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

  // Payment method
  String _paymentMethod = 'Płatność przy odbiorze';

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
            controller: _firstNameController, // Use external controller
            searchController: _customerSearchController, // Use search controller
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

  Widget _buildCheckoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _processCheckout();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'ZAMÓW',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _fillCustomerInfo(Customer customer) {
    setState(() {
      _selectedCustomer = customer;

      // Fill customer information into form fields
      // Use setText method to avoid triggering search
      _customerSearchController.setText(customer.fullName);
      _taxCodeController.text = customer.billingCompany;
      _address1Controller.text = customer.billingAddress;
      _phoneController.text = customer.billingPhone;
      _emailController.text = customer.email;
    });
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Tworzenie zamówienia...'),
          ],
        ),
      ),
    );

    try {
      // Calculate net total (before tax) for order notes
      double netTotal = 0;
      for (var item in items) {
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

      // Prepare line items with net price (before tax)
      final lineItems = items.map((item) {
        double basePrice = double.tryParse(item.price) ?? 0;
        return {
          'product_id': item.productId,
          'quantity': item.quantity,
          'total': '${basePrice * item.quantity}',
          'subtotal': '${basePrice * item.quantity}', // Subtotal equals total
        };
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
      final taxFeeLines = [
        {
          'name': 'Tax (${_taxRate.toStringAsFixed(2)}x)',
          'total': taxAmount.toStringAsFixed(2),
        },
      ];

      // Create order
      final order = await orderProvider.createOrder(
        billingInfo: billingInfo,
        lineItems: lineItems,
        paymentMethod: 'cod',
        paymentMethodTitle: _paymentMethod,
        customerNote: customerNote,
        feeLines: taxFeeLines,
      );

      // Close loading dialog
      Navigator.of(context).pop();

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

        // Navigate back to home or order list
        context.go('/orders');
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas tworzenia zamówienia. Spróbuj ponownie!'),
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
