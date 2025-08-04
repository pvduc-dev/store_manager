import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/customer_provider.dart';
import 'package:store_manager/models/customer.dart';
import 'package:go_router/go_router.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                if (customerProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final customers = customerProvider.filteredCustomers;

                if (customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          customerProvider.searchQuery.isNotEmpty
                              ? 'Không tìm thấy khách hàng'
                              : 'Chưa có khách hàng nào',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => customerProvider.loadCustomers(),
                  child: ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return _buildCustomerCard(context, customer);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add customer screen
          // context.push('/customers/add');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return ListTile(
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(customer.avatarUrl),
        backgroundColor: Colors.grey[300],
      ),
      title: Text(
        customer.fullName.isNotEmpty 
            ? customer.fullName 
            : customer.username,
      ),
      subtitle: Text(customer.email),
      onTap: () {
        context.push('/customers/${customer.id}');
      },
    );
  }
}