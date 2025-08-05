import 'package:flutter/material.dart';
import 'package:store_manager/widgets/organism/customer_form.dart';

class CustomerNewScreen extends StatelessWidget {
  const CustomerNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm khách hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CustomerForm(),
          ],
        ),
      ),
    );
  }
}