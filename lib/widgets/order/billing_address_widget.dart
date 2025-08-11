import 'package:flutter/material.dart';

class BillingAddressWidget extends StatelessWidget {
  final TextEditingController lastNameController;
  final TextEditingController nipController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final String? companyName; // Optional company name for display

  const BillingAddressWidget({
    super.key,
    required this.lastNameController,
    required this.nipController,
    required this.addressController,
    required this.phoneController,
    required this.emailController,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {
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
              // Name
              Text(
                lastNameController.text.isNotEmpty
                    ? lastNameController.text
                    : 'Chưa nhập họ và tên',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: lastNameController.text.isNotEmpty
                      ? Colors.grey[700]
                      : Colors.grey[400],
                  fontStyle: lastNameController.text.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),

              // NIP (Tax Code) - now more prominent
              Text(
                nipController.text.isNotEmpty
                    ? 'Mã số thuế: ${nipController.text}'
                    : 'Mã số thuế: Chưa nhập',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: nipController.text.isNotEmpty
                      ? Colors.grey[700]
                      : Colors.grey[400],
                  fontStyle: nipController.text.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),

              // Address
              Text(
                addressController.text.isNotEmpty
                    ? addressController.text
                    : 'Chưa nhập địa chỉ',
                style: TextStyle(
                  fontSize: 14,
                  color: addressController.text.isNotEmpty
                      ? Colors.grey[700]
                      : Colors.grey[400],
                  fontStyle: addressController.text.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),

              // Phone
              Text(
                phoneController.text.isNotEmpty
                    ? phoneController.text
                    : 'Chưa nhập số điện thoại',
                style: TextStyle(
                  fontSize: 14,
                  color: phoneController.text.isNotEmpty
                      ? Colors.grey[700]
                      : Colors.grey[400],
                  fontStyle: phoneController.text.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 4),

              // Email
              Text(
                emailController.text.isNotEmpty
                    ? emailController.text
                    : 'Chưa nhập email',
                style: TextStyle(
                  fontSize: 14,
                  color: emailController.text.isNotEmpty
                      ? Colors.grey[700]
                      : Colors.grey[400],
                  fontStyle: emailController.text.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
