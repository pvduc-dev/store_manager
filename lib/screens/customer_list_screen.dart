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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Đồng bộ search controller với provider state
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    _syncSearchController(customerProvider);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      customerProvider.loadMoreCustomers();
    }
  }

  void _syncSearchController(CustomerProvider customerProvider) {
    // Đồng bộ controller với provider state
    if (customerProvider.searchQuery != _searchController.text) {
      _searchController.text = customerProvider.searchQuery;
    }
  }

  void _performSearch() {
    final customerProvider = Provider.of<CustomerProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      customerProvider.searchCustomers(query);
    } else {
      customerProvider.clearSearch();
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    _searchController.clear();
    customerProvider.clearSearch();
    await customerProvider.loadCustomers(refresh: true);
  }

  void _clearSearch() {
    _searchController.clear();
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    customerProvider.clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Customer List
            Expanded(
              child: Consumer<CustomerProvider>(
                builder: (context, customerProvider, child) {
                  if (customerProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = customerProvider.customers;

                  if (customers.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () => _onRefresh(context),
                      child: ListView(
                        children: [
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    customerProvider.isSearching
                                        ? Icons.search_off
                                        : Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    customerProvider.isSearching
                                        ? 'Nie znaleziono klientów'
                                        : 'Nie ma jeszcze klientów',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (customerProvider.isSearching) ...[
                                    SizedBox(height: 8),
                                    Text(
                                      'Spróbuj znaleźć klienta z innymi słowami kluczowymi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => _onRefresh(context),
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length + 
                          (customerProvider.hasMoreData && !customerProvider.isSearching ? 1 : 0),
                      separatorBuilder: (context, index) {
                        return const SizedBox.shrink();
                      },
                      itemBuilder: (context, index) {
                        if (index == customers.length && !customerProvider.isSearching) {
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
          context.push('/customers/new');
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(
          customer.firstName.isNotEmpty 
              ? customer.firstName[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Text(
        customer.firstName.isNotEmpty 
            ? customer.firstName 
            : 'Brak nazwy',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (customer.phone.isNotEmpty) ...[
                Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    customer.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
              if (customer.phone.isNotEmpty && customer.nip.isNotEmpty)
                const SizedBox(width: 16),
              if (customer.nip.isNotEmpty) ...[
                Icon(Icons.business, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'NIP: ${customer.nip}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.grey[600]),
        onTap: () {
          context.push('/customers/${customer.id}');
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      Icon(Icons.search, color: Colors.grey[600]),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: 16),
                          onSubmitted: (_) => _performSearch(),
                          decoration: InputDecoration(
                            hintText: 'Wyszukaj klienta',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            suffixIcon: Consumer<CustomerProvider>(
                              builder: (context, customerProvider, child) {
                                if (customerProvider.isSearching) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _clearSearch();
                                    },
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              FilledButton(onPressed: _performSearch, child: Text('Szukaj')),
            ],
          ),
        ],
      ),
    );
  }
}