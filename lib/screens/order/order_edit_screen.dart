import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/widgets/order/app_text_input.dart';
import 'package:store_manager/widgets/order/customer_search_widget.dart';
import 'package:store_manager/widgets/order/billing_address_widget.dart';
import 'package:store_manager/widgets/order/cart_item_widget.dart';
import 'package:store_manager/providers/order_provider.dart';
import 'package:store_manager/models/order.dart';
import 'package:store_manager/models/customer.dart';

class OrderEditScreen extends StatefulWidget {
  final Order order;

  const OrderEditScreen({super.key, required this.order});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _lastNameController;
  late final TextEditingController _nipController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _notesController;

  String? _selectedCustomerCompany;
  bool _hasSelectedCustomer = false;
  double _netto = 0.0;
  double _brutto = 0.0;
  bool _isLoading = false;
  late List<_EditableLineItem> _editableItems;
  late final TextEditingController _taxRateController;
  double _taxRate = 1.23;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fillOrderData();
  }

  void _initializeControllers() {
    _lastNameController = TextEditingController();
    _nipController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _notesController = TextEditingController();
    _taxRateController = TextEditingController(text: '1.23');
  }

  void _fillOrderData() {
    final order = widget.order;

    _lastNameController.text =
        '${order.billing.firstName} ${order.billing.lastName}'.trim();
    _nipController.text = order.billing.company;
    _addressController.text = order.billing.address1;
    _phoneController.text = order.billing.phone;
    _emailController.text = order.billing.email;
    _notesController.text = order.customerNote;

    if (order.billing.company.isNotEmpty) {
      _selectedCustomerCompany = order.billing.company;
      _hasSelectedCustomer = true;
    }

    _calculateOrderTotals();
  }

  void _calculateOrderTotals() {
    // Khởi tạo danh sách item có thể chỉnh sửa từ order hiện tại
    _editableItems = widget.order.lineItems
        .map(
          (it) => _EditableLineItem(
            id: it.id,
            productId: it.productId,
            name: it.name,
            sku: it.sku,
            imageUrl: it.image?.src ?? '',
            quantity: it.quantity,
            unitPrice: it.price, // giá đơn vị
          ),
        )
        .toList();

    // Lấy _netto và _brutto từ meta_data
    _netto = _getMetaDataValue('GIA_THUONG_LUONG', 0.0);
    _brutto = _getMetaDataValue('total', 0.0);

    // Khởi tạo hệ số thuế từ _brutto và _netto
    if (_netto > 0 && _brutto > 0) {
      _taxRate = _brutto / _netto;
      
      // Kiểm tra và giới hạn hệ số thuế trong khoảng hợp lý
      if (!_isValidTaxRate(_taxRate)) {
        debugPrint('Warning: Calculated tax rate $_taxRate is outside valid range (1.0-2.0). Clamping to valid range.');
        _taxRate = _taxRate.clamp(1.0, 2.0);
      }
      
      _taxRateController.text = _taxRate.toStringAsFixed(2);
    } else {
      // Nếu không thể tính được từ meta_data, sử dụng giá trị mặc định
      _taxRate = 1.23;
      _taxRateController.text = _taxRate.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _nipController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(child: _buildForm()),
          _buildSaveButton(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Sửa đơn hàng',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildOrderInfoSection(),
            const SizedBox(height: 32),
            _buildCustomerSection(),
            const SizedBox(height: 32),
            _buildOrderItemsSection(),
            const SizedBox(height: 24),
            _buildOrderSummarySection(),
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

  Widget _buildOrderInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit, color: Colors.blue[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Thông tin đơn hàng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Mã đơn hàng',
            '#${widget.order.number.isNotEmpty ? widget.order.number : widget.order.id}',
          ),
          _buildInfoRow('Trạng thái', widget.order.orderStatus.displayName),
          _buildInfoRow('Ngày tạo', _formatDateTime(widget.order.dateCreated)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
      placeholder: 'Ghi chú về đơn hàng...',
      controller: _notesController,
      prefixIcon: Icons.note,
      maxLines: 4,
    );
  }

  Widget _buildOrderItemsSection() {
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
              for (int i = 0; i < _editableItems.length; i++) ...[
                _buildEditableItem(_editableItems[i], i),
                if (i < _editableItems.length - 1) _buildDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableItem(_EditableLineItem item, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: CartItemWidget(
        productName:
            '${item.name}${item.sku.isNotEmpty ? ' • ${item.sku}' : ''}',
        productImageUrl: item.imageUrl,
        initialPrice: item.unitPrice,
        initialQuantity: item.quantity,
        onUpdate: (newPrice, newQty) {
          setState(() {
            _editableItems[index] = item.copyWith(
              unitPrice: newPrice,
              quantity: newQty,
            );
            _recalculateTotals();
          });
        },
        onDelete: () {
          setState(() {
            _editableItems.removeAt(index);
            _recalculateTotals();
          });
          _showSnackBarSafely('Đã xoá sản phẩm khỏi đơn hàng');
        },
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng quan đơn hàng',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Hệ số thuế', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                height: 40,
                child: TextField(
                  controller: _taxRateController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*([.,]\d{0,2})?$'),
                    ),
                  ],
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: 'x',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onChanged: _onTaxRateChanged,
                  onEditingComplete: () {
                    _taxRateController.text = _taxRate.toStringAsFixed(2);
                    FocusScope.of(context).unfocus();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Netto',
            '${_netto.toStringAsFixed(2)} zł',
          ),
          if ((_taxRate - 1) > 0)
            _buildSummaryRow(
              'Thuế',
              '${(_netto * (_taxRate - 1)).toStringAsFixed(2)} zł',
            ),
          if (double.parse(widget.order.shippingTotal) > 0)
            _buildSummaryRow(
              'Phí vận chuyển',
              '${(double.tryParse(widget.order.shippingTotal) ?? 0).toStringAsFixed(2)} zł',
            ),
          const Divider(height: 20, thickness: 1),
          _buildSummaryRow(
            'Brutto',
            '${_brutto.toStringAsFixed(2)} zł',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildSaveButton() {
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
          onPressed: _isLoading ? null : _handleSaveOrder,
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
                  'Lưu thay đổi',
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

  // Save order process
  Future<void> _handleSaveOrder() async {
    if (!mounted) return;

    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Vui lòng điền đầy đủ thông tin bắt buộc');
      return;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      _showSnackBarSafely(
        '🔄 Đang cập nhật đơn hàng...',
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      );

      final orderData = await _prepareOrderData();
      final updatedOrder = await _updateOrder(orderData);

      if (updatedOrder != null) {
        await _handleSuccessfulUpdate(updatedOrder);
      } else {
        throw Exception('Không thể cập nhật đơn hàng');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Lỗi khi cập nhật đơn hàng: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _prepareOrderData() async {
    final customerData = _buildCustomerData();
    final lineItems = _buildLineItems();
    final shippingLines = _buildShippingLines();

    final orderData = {
      'billing': customerData,
      'shipping': customerData,
      'line_items': lineItems,
      'shipping_lines': shippingLines,
      'customer_note': _notesController.text.isNotEmpty
          ? _notesController.text
          : '',
      'meta_data': [
        {'key': 'total', 'value': _brutto.toStringAsFixed(2)},
        {'key': 'GIA_THUONG_LUONG', 'value': _netto.toStringAsFixed(2)},
        {
          'key': 'total_tax',
          'value': (_netto * (_taxRate - 1)).toStringAsFixed(2),
        },
      ],
    };

    print(
      'OrderEditScreen: Đang chuẩn bị dữ liệu cập nhật đơn hàng: ${orderData.toString()}',
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

  List<Map<String, dynamic>> _buildLineItems() {
    return _editableItems.map((item) {
      final total = item.unitPrice * item.quantity;
      return {
        'id': item.id,
        'product_id': item.productId,
        'quantity': item.quantity,
        'total': total.toStringAsFixed(2),
        'price': item.unitPrice.toStringAsFixed(2),
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildShippingLines() {
    return [
      {
        'method_id': 'flat_rate',
        'method_title': 'Phí vận chuyển',
        'total': widget.order.shippingTotal,
      },
    ];
  }

  Future<dynamic> _updateOrder(Map<String, dynamic> orderData) async {
    if (!mounted) return null;

    try {
      final orderProvider = context.read<OrderProvider>();
      final result = await orderProvider.updateOrder(
        widget.order.id,
        orderData,
      );
      return result;
    } catch (e) {
      debugPrint('Error updating order: $e');
      return null;
    }
  }

  Future<void> _handleSuccessfulUpdate(dynamic updatedOrder) async {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) {
        try {
          _showSuccessMessage('✅ Cập nhật đơn hàng thành công!');
          context.pop();
        } catch (e) {
          debugPrint('Error in post frame callback: $e');
        }
      }
    });
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
    );
  }

  void _showSnackBarSafely(
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!mounted) return;

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
          debugPrint('Error showing SnackBar: $e');
        }
      }
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _recalculateTotals() {
    // Tính lại _netto từ sản phẩm hiện tại
    final calculatedNetto = _editableItems.fold<double>(
      0,
      (sum, it) => sum + it.unitPrice * it.quantity,
    );
    
    // Cập nhật _netto nếu có thay đổi
    if (calculatedNetto != _netto) {
      _netto = calculatedNetto;
      
      // Chỉ tính lại _brutto nếu _netto > 0
      if (_netto > 0) {
        _brutto = _netto * _taxRate;
      } else {
        // Nếu _netto = 0, đặt _brutto = 0
        _brutto = 0.0;
      }
    }
    
    // Không cập nhật _taxRate ở đây vì:
    // 1. Nó sẽ làm mất giá trị người dùng đã nhập
    // 2. _taxRate chỉ được cập nhật khi người dùng thay đổi trực tiếp
    // 3. Khi thay đổi sản phẩm, chúng ta muốn giữ nguyên hệ số thuế người dùng đã thiết lập
  }

  void _onTaxRateChanged(String value) {
    if (value.trim().isEmpty) return;
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null || parsed <= 0) return;
    
    // Giới hạn hệ số thuế trong khoảng hợp lý (1.0 - 2.0)
    final clampedTaxRate = parsed.clamp(1.0, 2.0);
    
    setState(() {
      _taxRate = clampedTaxRate;
      // Tính lại _brutto dựa trên _netto và _taxRate mới
      _brutto = _netto * _taxRate;
      
      // Cập nhật text controller nếu giá trị bị thay đổi do clamp
      if (clampedTaxRate != parsed) {
        _taxRateController.text = _taxRate.toStringAsFixed(2);
      }
    });
  }

  /// Cập nhật _taxRate dựa trên _brutto và _netto hiện tại
  void _updateTaxRateFromTotals() {
    if (_netto > 0) {
      _taxRate = _brutto / _netto;
      _taxRateController.text = _taxRate.toStringAsFixed(2);
    }
  }

  /// Cập nhật _taxRate để phù hợp với tổng tiền hiện tại
  /// Được gọi khi muốn tính lại hệ số thuế dựa trên _brutto và _netto
  void _recalculateTaxRate() {
    if (_netto > 0) {
      _taxRate = _brutto / _netto;
      _taxRateController.text = _taxRate.toStringAsFixed(2);
    }
  }

  /// Validate hệ số thuế có hợp lệ không
  bool _isValidTaxRate(double taxRate) {
    return taxRate >= 1.0 && taxRate <= 2.0;
  }

  /// Lấy giá trị từ meta_data theo key
  T _getMetaDataValue<T>(String key, T defaultValue) {
    try {
      if (widget.order.metaData.isEmpty) {
        debugPrint('Meta_data is empty for order ${widget.order.id}');
        return defaultValue;
      }
      
      final metaItem = widget.order.metaData.firstWhere(
        (item) => item['key'] == key,
        orElse: () => <String, dynamic>{},
      );
      
      if (metaItem.isEmpty) {
        debugPrint('Meta_data key "$key" not found for order ${widget.order.id}');
        return defaultValue;
      }
      
      final value = metaItem['value'];
      if (value == null) {
        debugPrint('Meta_data value is null for key "$key" in order ${widget.order.id}');
        return defaultValue;
      }
      
      if (T == double) {
        final parsed = double.tryParse(value.toString());
        if (parsed == null) {
          debugPrint('Failed to parse meta_data value "$value" as double for key "$key"');
          return defaultValue;
        }
        return parsed as T;
      } else if (T == int) {
        final parsed = int.tryParse(value.toString());
        if (parsed == null) {
          debugPrint('Failed to parse meta_data value "$value" as int for key "$key"');
          return defaultValue;
        }
        return parsed as T;
      } else if (T == String) {
        return value.toString() as T;
      } else if (T == bool) {
        return (value == 'true' || value == true) as T;
      }
      
      return defaultValue;
    } catch (e) {
      debugPrint('Error getting meta_data value for key "$key" in order ${widget.order.id}: $e');
      return defaultValue;
    }
  }
}

class _EditableLineItem {
  final int id;
  final int productId;
  final String name;
  final String sku;
  final String imageUrl;
  final int quantity;
  final double unitPrice;

  _EditableLineItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.sku,
    required this.imageUrl,
    required this.quantity,
    required this.unitPrice,
  });

  _EditableLineItem copyWith({int? quantity, double? unitPrice}) {
    return _EditableLineItem(
      id: id,
      productId: productId,
      name: name,
      sku: sku,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
