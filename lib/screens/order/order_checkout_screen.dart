import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:store_manager/widgets/order/app_text_input.dart';

class OrderCheckoutScreen extends StatefulWidget {
  const OrderCheckoutScreen({super.key});

  @override
  State<OrderCheckoutScreen> createState() => _OrderCheckoutScreenState();
}

class _OrderCheckoutScreenState extends State<OrderCheckoutScreen> {
  final TextEditingController _lastNameController = TextEditingController(
    text: 'Damian Wrobel',
  );
  final TextEditingController _nipController = TextEditingController(
    text: '6631884810',
  );
  final TextEditingController _addressController = TextEditingController(
    text: 'Gostkow 44, 26-120, Blizyn',
  );
  final TextEditingController _phoneController = TextEditingController(
    text: '660325969',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'wrublu9@gmail.com',
  );
  final TextEditingController _notesController = TextEditingController();
  
  // Controllers for editable summary fields
  final TextEditingController _totalController = TextEditingController(text: '689.00');
  final TextEditingController _nettoController = TextEditingController(text: '689.00');
  final TextEditingController _bruttoController = TextEditingController(text: '847.47');

  @override
  void initState() {
    super.initState();
    
    // Add listeners to update billing address section
    _lastNameController.addListener(() => setState(() {}));
    _nipController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _lastNameController.dispose();
    _nipController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _totalController.dispose();
    _nettoController.dispose();
    _bruttoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            context.pop();
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Form
          Expanded(child: _buildForm()),
          // Fixed continue button
          _buildContinueButton(),
        ],
      ),
    );
  }



  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Last Name field with arrow
          AppTextInput(
            label: 'Nazwisko *',
            placeholder: 'Nhập họ tên',
            controller: _lastNameController,
            prefixIcon: Icons.person,
            suffixIcon: Icons.arrow_forward,
            onSuffixIconPressed: () {
              // Handle next action
            },
          ),
          const SizedBox(height: 16),

          // tên công ty  
          AppTextInput(
            label: 'Tên công ty *',
            placeholder: 'Nhập tên công ty',
            controller: _lastNameController,
            prefixIcon: Icons.business,
          ),
          const SizedBox(height: 16),

          // Address field
          AppTextInput(
            label: 'Địa chỉ *',
            placeholder: 'Nhập địa chỉ giao hàng',
            controller: _addressController,
            prefixIcon: Icons.location_on,
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // NIP field
          AppTextInput(
            label: 'NIP (tuỳ chọn)',
            placeholder: 'Nhập mã số thuế',
            controller: _nipController,
            prefixIcon: Icons.business,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          

          // Phone field
          AppTextInput(
            label: 'Số điện thoại *',
            placeholder: 'Nhập số điện thoại',
            controller: _phoneController,
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Email field
          AppTextInput(
            label: 'Địa chỉ email *',
            placeholder: 'Nhập địa chỉ email',
            controller: _emailController,
            prefixIcon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email không được để trống';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

                      // Notes field
            AppTextInput(
              label: 'Ghi chú đơn hàng (tuỳ chọn)',
              placeholder:
                  'Ghi chú về đơn hàng, ví dụ: thời gian hay chỉ dẫn địa điểm gian hàng chi tiết hơn',
              controller: _notesController,
              prefixIcon: Icons.note,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            
            // Order Items Section
            _buildOrderItemsSection(),
            const SizedBox(height: 24),
            
            // Order Summary Section
            _buildOrderSummarySection(),
            const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
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
          onPressed: () {
            // Handle checkout
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Đặt hàng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
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
        
        // Order items list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildOrderItem(
                image: 'assets/images/pokemon_card_pack.png',
                name: 'karty pokemon 55 tęczowy x 10',
                quantity: 10,
                price: 65.00,
              ),
              _buildDivider(),
              _buildOrderItem(
                image: 'assets/images/pokemon_box.png',
                name: 'karty pokemon 360 prismatic x 12',
                quantity: 12,
                price: 156.00,
              ),
              _buildDivider(),
              _buildOrderItem(
                image: 'assets/images/keychains.png',
                name: 'breloczki głowa labubu muzyka x 12',
                quantity: 12,
                price: 132.00,
              ),
              _buildDivider(),
              _buildOrderItem(
                image: 'assets/images/baby_three.png',
                name: 'baby three x 12',
                quantity: 12,
                price: 336.00,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem({
    required String image,
    required String name,
    required int quantity,
    required double price,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Product image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: image.startsWith('http')
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Số lượng: $quantity',
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
            '${price.toStringAsFixed(2)} zł',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
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

  Widget _buildOrderSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin đơn hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Subtotal
              _buildSummaryRow('Tổng số phụ', '689.00 zł'),
              const SizedBox(height: 8),
              
              // Payment method
              _buildSummaryRow('Phương thức thanh toán:', 'Płatność przy odbiorze'),
              const SizedBox(height: 16),
              
              // Total - Editable
              _buildEditableSummaryRow(
                'Tổng cộng',
                '689.00',
                _totalController,
              ),
              const SizedBox(height: 8),
              
              // Netto - Editable
              _buildEditableSummaryRow(
                'Razem (Netto)',
                '689.00',
                _nettoController,
              ),
              const SizedBox(height: 8),
              
              // Brutto - Editable
              _buildEditableSummaryRow(
                'Suma (Brutto)',
                '847.47',
                _bruttoController,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Billing Address Section
        _buildBillingAddressSection(),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableSummaryRow(
    String label,
    String defaultValue,
    TextEditingController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        
        // Editable input field
        Container(
          width: 120,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              suffixText: ' zł',
              suffixStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              isDense: true,
            ),
            onChanged: (value) {
              // Handle value change if needed
            },
            
          ),
        ),
      ],
    );
  }

  Widget _buildBillingAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Địa chỉ thanh toán',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                _lastNameController.text.isNotEmpty 
                    ? _lastNameController.text 
                    : 'Damian Wrobel',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              
              // NIP
              Text(
                _nipController.text.isNotEmpty 
                    ? _nipController.text 
                    : '6631884810',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              
              // Address
              Text(
                _addressController.text.isNotEmpty 
                    ? _addressController.text 
                    : 'Gostkow 44, 26-120, Blizyn',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              
              // Phone
              Text(
                _phoneController.text.isNotEmpty 
                    ? _phoneController.text 
                    : '660325969',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
