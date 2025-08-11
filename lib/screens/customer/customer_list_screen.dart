import 'package:cached_network_image/cached_network_image.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      customerProvider.loadMoreCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khách hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Consumer<CustomerProvider>(
              builder: (context, customerProvider, child) {
                return TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Tìm theo tên, số điện thoại, email, NIP',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixIcon: customerProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              customerProvider.searchCustomers('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    customerProvider.searchCustomers(value);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
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
                    onRefresh: () => customerProvider.loadCustomers(refresh: true),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: customers.length + (customerProvider.hasMoreData && customerProvider.searchQuery.isEmpty ? 1 : 0),
                      separatorBuilder: (context, index) {
                        if (index == customers.length - 1 && customerProvider.hasMoreData && customerProvider.searchQuery.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: 8);
                      },
                      itemBuilder: (context, index) {
                        if (index == customers.length) {
                          // Load more indicator
                          return customerProvider.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Center(child: CircularProgressIndicator()),
                                )
                              : const SizedBox.shrink();
                        }
                        
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add customer screen
          context.push('/customers/new');
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
        backgroundImage: CachedNetworkImageProvider(customer.avatarUrl),
        backgroundColor: Colors.grey[300],
      ),
      title: Text(
        customer.fullName.isNotEmpty 
            ? customer.fullName 
            : customer.username,
      ),
      subtitle: Text(customer.email),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[600]),
      onTap: () {
        context.push('/customers/${customer.id}');
      },
    );
  }
}