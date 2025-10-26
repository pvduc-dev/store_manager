import 'package:flutter/material.dart';
import 'package:store_manager/models/customer.dart';
import 'package:store_manager/services/customer_service.dart';
import 'dart:async';

class CustomerSearchDialog extends StatefulWidget {
  const CustomerSearchDialog({super.key});

  @override
  State<CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<CustomerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  String _lastQuery = '';
  Timer? _debounce;
  int _currentPage = 1;
  bool _hasMoreResults = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Auto focus search field khi dialog mở
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreResults) {
        _loadMoreCustomers();
      }
    }
  }

  Future<void> _loadCustomers({String query = ''}) async {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
      _currentPage = 1;
      _hasMoreResults = true;
    });

    try {
      final customers = await CustomerService.getCustomers(
        page: 1,
        perPage: 20,
        search: query,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = customers;
          _isSearching = false;
          _lastQuery = query;
          _hasMoreResults = customers.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        print('Error loading customers: $e');
      }
    }
  }

  Future<void> _loadMoreCustomers() async {
    if (_isLoadingMore || !_hasMoreResults || _lastQuery.length < 3) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final customers = await CustomerService.getCustomers(
        page: _currentPage + 1,
        perPage: 20,
        search: _lastQuery,
      );
      
      if (mounted) {
        setState(() {
          _searchResults.addAll(customers);
          _currentPage++;
          _isLoadingMore = false;
          _hasMoreResults = customers.length >= 20;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        print('Error loading more customers: $e');
      }
    }
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    
    // Clear results if less than 3 characters
    if (value.length < 3) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _lastQuery = value;
      });
      return;
    }
    
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      if (value != _lastQuery && value.length >= 3) {
        _loadCustomers(query: value);
      }
    });
  }

  void _selectCustomer(Customer customer) {
    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Wyszukaj klienta...',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
      ),
      body: _isSearching && _searchResults.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Zacznij wyszukiwać klientów'
                            : 'Nie znaleziono pasujących klientów',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _searchResults.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _searchResults.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final customer = _searchResults[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () => _selectCustomer(customer),
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            customer.fullName.isNotEmpty
                                ? customer.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                customer.email,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (customer.phone.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}