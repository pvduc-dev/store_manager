import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/widgets/order/app_text_input.dart';
import 'package:store_manager/widgets/order/customer_search_widget.dart';
import 'package:store_manager/widgets/order/order_item_widget.dart';
import 'package:store_manager/widgets/order/order_summary_widget.dart';
import 'package:store_manager/widgets/order/billing_address_widget.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/providers/order_provider.dart';
import 'package:store_manager/models/cart.dart';
import 'package:store_manager/models/customer.dart';

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _lastNameController;
  late final TextEditingController _nipController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  // State variables
  String? _selectedCustomerCompany;
  bool _hasSelectedCustomer = false;
  double _netto = 0.0;
  double _brutto = 0.0;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _setupListeners();
    _loadInitialData();
  }

  void _initializeControllers() {
    _lastNameController = TextEditingController();
    _nipController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _setupListeners() {
    _lastNameController.addListener(_onLastNameChanged);
    _nipController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().refresh();
      }
    });
  }

  void _onLastNameChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          if (_lastNameController.text.isEmpty) {
            _hasSelectedCustomer = false;
            _selectedCustomerCompany = null;
          }
        });
      }
    });
  }

  void _onFieldChanged() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  void _updateOrderValues(double netto, double brutto) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _netto = netto;
          _brutto = brutto;
          _isInitialized = true;
        });
      }
    });
  }

  void _updateOrderValuesFromCart(Cart cart) {
    if (!mounted) return;

    final totalPrice = _extractTotalPrice(cart);
    final newBrutto = totalPrice * 1.23;

    if (_netto != totalPrice || _brutto != newBrutto) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _netto = totalPrice;
            _brutto = newBrutto;
            _isInitialized = true;
          });
        }
      });
    }
  }

  double _extractTotalPrice(Cart cart) {
    return cart.total;
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _nipController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading && cartProvider.cart == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyCartMessage();
          }

          _initializeOrderValuesIfNeeded(cartProvider.cart);

          return Column(
            children: [
              Expanded(child: _buildForm(cartProvider.cart)),
              _buildContinueButton(cartProvider),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Đặt hàng',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          if (mounted && context.mounted) {
            try {
              context.pop();
            } catch (e) {
              debugPrint('Error popping context: $e');
            }
          }
        },
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildEmptyCartMessage() {
    return const Center(
      child: Text(
        'Giỏ hàng trống. Vui lòng thêm sản phẩm trước khi đặt hàng.',
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _initializeOrderValuesIfNeeded(Cart cart) {
    if (!_isInitialized && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _updateOrderValuesFromCart(cart);
        }
      });
    }
  }

  Widget _buildForm(Cart cart) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildCustomerSection(),
            const SizedBox(height: 32),
            _buildOrderItemsSection(cart),
            const SizedBox(height: 24),
            _buildOrderSummarySection(cart),
            const SizedBox(height: 24),
            if (_hasSelectedCustomer) ...[
              _buildBillingAddressSection(),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Column(
      children: [
        _buildCustomerSearchField(),
        const SizedBox(height: 16),
        _buildNipField(),
        const SizedBox(height: 16),
        _buildAddressField(),
        const SizedBox(height: 16),
        _buildPhoneField(),
        const SizedBox(height: 16),
        _buildEmailField(),
        const SizedBox(height: 16),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildCustomerSearchField() {
    return CustomerSearchWidget(
      label: 'Họ và tên *',
      placeholder: 'Tìm kiếm khách hàng...',
      controller: _lastNameController,
      prefixIcon: Icons.person,
      validator: _validateRequiredField,
      onCustomerSelected: _onCustomerSelected,
    );
  }

  Widget _buildNipField() {
    return AppTextInput(
      label: 'Mã số thuế *',
      placeholder: 'Ví dụ: 0123456789',
      controller: _nipController,
      prefixIcon: Icons.business,
      keyboardType: TextInputType.number,
      validator: _validateNipField,
    );
  }

  Widget _buildAddressField() {
    return AppTextInput(
      label: 'Địa chỉ *',
      placeholder: 'Ví dụ: 123 Đường ABC, Quận 1, TP.HCM',
      controller: _addressController,
      prefixIcon: Icons.location_on,
      maxLines: 1,
      validator: _validateRequiredField,
    );
  }

  Widget _buildPhoneField() {
    return AppTextInput(
      label: 'Số điện thoại *',
      placeholder: 'Ví dụ: 0901234567',
      controller: _phoneController,
      prefixIcon: Icons.phone,
      keyboardType: TextInputType.phone,
      validator: _validatePhoneField,
    );
  }

  Widget _buildEmailField() {
    return AppTextInput(
      label: 'Địa chỉ email *',
      placeholder: 'Ví dụ: example@gmail.com',
      controller: _emailController,
      prefixIcon: Icons.email,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmailField,
    );
  }

  Widget _buildNotesField() {
    return AppTextInput(
      label: 'Ghi chú đơn hàng (tuỳ chọn)',
      placeholder:
          'Ghi chú về đơn hàng, ví dụ: thời gian hay chỉ dẫn địa điểm gian hàng chi tiết hơn',
      controller: _notesController,
      prefixIcon: Icons.note,
      maxLines: 4,
    );
  }

  Widget _buildOrderItemsSection(Cart cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sản phẩm đã chọn',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              for (int i = 0; i < cart.items.length; i++) ...[
                OrderItemWidget(item: cart.items[i]),
                if (i < cart.items.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection(Cart cart) {
    return OrderSummaryWidget(cart: cart, onValuesChanged: _updateOrderValues);
  }

  Widget _buildBillingAddressSection() {
    return BillingAddressWidget(
      lastNameController: _lastNameController,
      nipController: _nipController,
      addressController: _addressController,
      phoneController: _phoneController,
      emailController: _emailController,
      companyName: _selectedCustomerCompany,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.grey.shade200,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildContinueButton(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : () => _handleCheckout(cartProvider),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Đặt hàng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  // Validation methods
  String? _validateRequiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Trường này không được để trống';
    }
    return null;
  }

  String? _validateNipField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mã số thuế không được để trống';
    }
    if (value.trim().length < 10) {
      return 'Mã số thuế phải có ít nhất 10 số';
    }
    return null;
  }

  String? _validatePhoneField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    if (!RegExp(r'^[0-9+\-\s()]+$').hasMatch(value)) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  String? _validateEmailField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  // Event handlers
  void _onCustomerSelected(Customer customer) {
    _fillCustomerData(customer);
    _updateCustomerSelection(customer);
    _showCustomerSelectionMessage(customer.fullName);
  }

  void _fillCustomerData(Customer customer) {
    _lastNameController.text = customer.fullName;
    _emailController.text = _getCustomerEmail(customer);
    _phoneController.text = _getCustomerPhone(customer);
    _addressController.text = _getCustomerAddress(customer);
    _nipController.text = _getCustomerNip(customer);
  }

  String _getCustomerEmail(Customer customer) {
    return customer.email.isNotEmpty
        ? customer.email
        : customer.billingAddress.email;
  }

  String _getCustomerPhone(Customer customer) {
    return customer.phone.isNotEmpty
        ? customer.phone
        : customer.billingAddress.phone;
  }

  String _getCustomerAddress(Customer customer) {
    return customer.billingAddress.fullAddress.isNotEmpty
        ? customer.billingAddress.fullAddress
        : '';
  }

  String _getCustomerNip(Customer customer) {
    if (customer.nip.isNotEmpty) return customer.nip;
    if (customer.company.isNotEmpty) return customer.company;
    return customer.billingAddress.company.isNotEmpty
        ? customer.billingAddress.company
        : '';
  }

  void _updateCustomerSelection(Customer customer) {
    if (!mounted) return;

    _selectedCustomerCompany = customer.company.isNotEmpty
        ? customer.company
        : customer.billingAddress.company;
    _hasSelectedCustomer = true;
    setState(() {});
  }

  void _showCustomerSelectionMessage(String customerName) {
    _showSnackBarSafely(
      'Đã chọn khách hàng: $customerName',
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
    );
  }

  // Checkout process
  Future<void> _handleCheckout(CartProvider cartProvider) async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Vui lòng điền đầy đủ thông tin bắt buộc');
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Hiển thị thông báo đang xử lý
      _showSnackBarSafely(
        '🔄 Đang tạo đơn hàng...',
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      );

      final orderData = await _prepareOrderData(cartProvider);
      final newOrder = await _createOrder(orderData);

      if (newOrder != null) {
        await _handleSuccessfulOrder(cartProvider, newOrder);
      } else {
        throw Exception('Không thể tạo đơn hàng');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Lỗi khi đặt hàng: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _prepareOrderData(
    CartProvider cartProvider,
  ) async {
    final cart = cartProvider.cart;
    if (cart == null) {
      throw Exception('Giỏ hàng trống');
    }

    final customerData = _buildCustomerData();
    final lineItems = _buildLineItems(cart);
    final shippingLines = _buildShippingLines(cart);
    final _netto = _calculateNetto(cart);
    final _brutto = _calculateBrutto(cart);

    final orderData = {
      'payment_method': 'cod',
      'payment_method_title': 'Thanh toán khi nhận hàng',
      'set_paid': false,
      'billing': customerData,
      'shipping': customerData,
      'line_items': lineItems,
      'shipping_lines': shippingLines,
      'fee_lines': [],
      'coupon_lines': [],
      'customer_note': _notesController.text.isNotEmpty
          ? _notesController.text
          : '',
      'status': 'pending',
      'total': _brutto.toStringAsFixed(2),
      'subtotal': _netto.toStringAsFixed(2),
      'total_tax': (_brutto - _netto).toStringAsFixed(2),
    };
    print(
      'OrderCheckoutScreen: Đang chuẩn bị dữ liệu đơn hàng: ${orderData.toString()}',
    );
    return orderData;
  }

  Map<String, dynamic> _buildCustomerData() {
    final nameParts = _lastNameController.text.split(' ');
    return {
      'first_name': nameParts.first,
      'last_name': nameParts.skip(1).join(' '),
      'company': _nipController.text,
      'address_1': _addressController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
    };
  }

  List<Map<String, dynamic>> _buildLineItems(Cart cart) {
    final lineItems = cart.items.map((item) {
      // Sử dụng totalPrice từ model CartItem mới
      final double totalPrice = item.totalPrice;

      // Tính giá đơn vị (giá mỗi sản phẩm)
      final double unitPrice = item.quantity > 0
          ? totalPrice / item.quantity
          : 0;

      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
        'total': totalPrice.toStringAsFixed(2),
        'unit_price': unitPrice.toStringAsFixed(2),
      };
    }).toList();

    return lineItems;
  }

  List<Map<String, dynamic>> _buildShippingLines(Cart cart) {
    return [
      {
        'method_id': 'flat_rate',
        'method_title': 'Phí vận chuyển',
        'total': '0', // Không có phí vận chuyển trong model mới
      },
    ];
  }

  double _calculateNetto(Cart cart) {
    return cart.subtotal;
  }

  double _calculateBrutto(Cart cart) {
    final netto = _calculateNetto(cart);
    return netto * 1.23; // Ví dụ: 200000 * 1.23 = 246000
  }

  Future<dynamic> _createOrder(Map<String, dynamic> orderData) async {
    if (!mounted) return null;

    try {
      final orderProvider = context.read<OrderProvider>();

      final result = await orderProvider.createOrder(orderData);

      return result;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  Future<void> _handleSuccessfulOrder(
    CartProvider cartProvider,
    dynamic newOrder,
  ) async {
    // Lưu thông tin order trước khi clear cart
    final orderNumber = newOrder.number ?? 'N/A';
    final orderTotal = newOrder.total != null ? '${newOrder.total}' : 'N/A';

    print(
      'OrderCheckoutScreen: Bắt đầu clear cart sau khi tạo đơn hàng thành công',
    );

    try {
      // Clear cart với timeout và retry
      await _clearCartWithRetry(cartProvider);
      print('OrderCheckoutScreen: Clear cart thành công');
    } catch (e) {
      print('OrderCheckoutScreen: Lỗi khi clear cart: $e');

      // Hiển thị thông báo cảnh báo nhưng không dừng quá trình
      if (mounted) {
        _showSnackBarSafely(
          '⚠️ Đơn hàng đã tạo thành công nhưng không thể xóa giỏ hàng. Vui lòng thử lại sau.',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        );
      }
      // Không throw error vì đơn hàng đã tạo thành công
    }

    // Kiểm tra mounted sau khi clear cart
    if (!mounted) return;

    // Sử dụng addPostFrameCallback để đảm bảo context an toàn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          // Hiển thị thông báo thành công với thông tin chi tiết
          _showSuccessMessage(
            '🎉 Đặt hàng thành công!\n📝 Mã đơn hàng: #$orderNumber\n💰 Tổng tiền: $orderTotal',
          );

          // Chuyển hướng ngay lập tức đến màn hình danh sách đơn hàng
          _navigateToOrders();
        } catch (e) {
          debugPrint('Error in post frame callback: $e');
        }
      }
    });
  }

  /// Clear cart với retry logic
  Future<void> _clearCartWithRetry(CartProvider cartProvider) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        print(
          'OrderCheckoutScreen: Lần thử ${retryCount + 1}/$maxRetries - Clear cart',
        );
        await cartProvider.clearCart();
        return; // Thành công
      } catch (e) {
        retryCount++;
        print(
          'OrderCheckoutScreen: Lần thử $retryCount/$maxRetries - Lỗi clear cart: $e',
        );

        // Nếu là lỗi 401, thử lại ngay lập tức
        if (e.toString().contains('401') ||
            e.toString().contains('Authentication failed')) {
          if (retryCount < maxRetries) {
            print('OrderCheckoutScreen: Lỗi 401, thử lại ngay lập tức...');
            continue;
          } else {
            print(
              'OrderCheckoutScreen: Đã thử hết $maxRetries lần với lỗi 401',
            );
            rethrow;
          }
        }

        // Với các lỗi khác, đợi trước khi thử lại
        if (retryCount < maxRetries) {
          print(
            'OrderCheckoutScreen: Đợi 1 giây trước khi thử lại clear cart...',
          );
          await Future.delayed(const Duration(seconds: 1));
        } else {
          print('OrderCheckoutScreen: Đã thử hết $maxRetries lần clear cart');
          rethrow;
        }
      }
    }
  }

  /// Chuyển hướng đến màn hình danh sách đơn hàng
  void _navigateToOrders() {
    if (!mounted || !context.mounted) return;

    try {
      print(
        'OrderCheckoutScreen: Chuyển hướng ngay lập tức đến màn hình danh sách đơn hàng',
      );

      // Thông báo cho OrderProvider để refresh danh sách
      final orderProvider = context.read<OrderProvider>();
      orderProvider.loadOrders(refresh: true);

      // Chuyển hướng
      context.go('/orders');
    } catch (e) {
      debugPrint('Error navigating to orders: $e');
      // Fallback: thử pop context
      try {
        context.pop();
      } catch (e2) {
        debugPrint('Error popping context: $e2');
      }
    }
  }

  void _showErrorMessage(String message) {
    _showSnackBarSafely(
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    );
  }

  void _showSuccessMessage(String message) {
    _showSnackBarSafely(
      message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Xem đơn hàng',
        textColor: Colors.white,
        onPressed: () {
          if (mounted && context.mounted) {
            try {
              print(
                'OrderCheckoutScreen: Chuyển hướng từ SnackBar đến danh sách đơn hàng',
              );
              context.go('/orders');
            } catch (e) {
              debugPrint('Error navigating to orders from snackbar: $e');
            }
          }
        },
      ),
    );
  }

  /// Hiển thị SnackBar một cách an toàn, kiểm tra widget state trước khi hiển thị
  void _showSnackBarSafely(
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    // Kiểm tra widget có còn mounted và context có còn valid không
    if (!mounted) return;

    // Sử dụng addPostFrameCallback để đảm bảo context đã sẵn sàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: backgroundColor ?? Colors.black87,
              duration: duration ?? const Duration(seconds: 3),
              action: action,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        } catch (e) {
          // Log lỗi nếu có vấn đề với ScaffoldMessenger
          debugPrint('Error showing SnackBar: $e');
        }
      }
    });
  }
}
