import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/customer_provider.dart';
import 'package:store_manager/widgets/organism/customer_form.dart';

class CustomerEditScreen extends StatelessWidget {
  final String customerId;
  const CustomerEditScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().getCustomerById(int.parse(customerId));
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Chỉnh sửa khách hàng'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CustomerForm(customer: customer),
          ],
        ),
      ),
    );
  }
}