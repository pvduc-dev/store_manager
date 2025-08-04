import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/customer_provider.dart';

class CustomerDetailScreen extends StatefulWidget {
  final String customerId;
  
  const CustomerDetailScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerId = int.tryParse(widget.customerId);
      if (customerId != null) {
        context.read<CustomerProvider>().loadCustomerById(customerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerId = int.tryParse(widget.customerId);
    
    if (customerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi tiết khách hàng')),
        body: const Center(
          child: Text('ID khách hàng không hợp lệ'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết khách hàng'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          final customer = customerProvider.getCustomerById(customerId);
          
          if (customer == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer basic info card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(customer.avatarUrl),
                              backgroundColor: Colors.grey[300],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.fullName.isNotEmpty 
                                        ? customer.fullName 
                                        : customer.username,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.email,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'ID',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    customer.id.toString(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Trạng thái',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    customer.isPayingCustomer ? 'Đã mua' : 'Chưa mua',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: customer.isPayingCustomer 
                                          ? Colors.green 
                                          : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Contact information
                const Text(
                  'Thông tin liên hệ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (customer.billing.company.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.business),
                            title: const Text('Công ty'),
                            subtitle: Text(customer.billing.company),
                          ),
                        if (customer.billing.phone.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.phone),
                            title: const Text('Số điện thoại'),
                            subtitle: Text(customer.billing.phone),
                          ),
                        if (customer.billingAddress.isNotEmpty)
                          ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Địa chỉ'),
                            subtitle: Text(customer.billingAddress),
                          ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Ngày tham gia'),
                          subtitle: Text(_formatDate(customer.dateCreated)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}