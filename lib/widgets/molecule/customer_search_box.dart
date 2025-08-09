import 'package:flutter/material.dart';
import 'package:store_manager/models/customer.dart';
import 'package:store_manager/services/customer_service.dart';
import 'dart:async';

// Controller để parent có thể control CustomerSearchBox
class CustomerSearchController {
  _CustomerSearchBoxState? _state;
  
  void _attach(_CustomerSearchBoxState state) {
    _state = state;
  }
  
  void _detach() {
    _state = null;
  }
  
  void setText(String text) {
    _state?.setText(text);
  }
}

class CustomerSearchBox extends StatefulWidget {
  final Function(Customer) onCustomerSelected;
  final String? initialValue;
  final String? Function(String?)? validator;
  final Function(String)? onTextChanged;
  final TextEditingController? controller; // External controller option
  final CustomerSearchController? searchController; // Search controller để parent control

  const CustomerSearchBox({
    super.key,
    required this.onCustomerSelected,
    this.initialValue,
    this.validator,
    this.onTextChanged,
    this.controller,
    this.searchController,
  });

  @override
  State<CustomerSearchBox> createState() => _CustomerSearchBoxState();
}

class _CustomerSearchBoxState extends State<CustomerSearchBox> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;
  String _lastQuery = '';
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _isSelecting = false; // Flag để tránh search khi đang select customer
  bool _isProgrammaticChange = false; // Flag để tránh search khi parent set text
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Use external controller if provided, otherwise create internal one
    _controller = widget.controller ?? TextEditingController();
    
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
    
    // Attach search controller if provided
    widget.searchController?._attach(this);
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay để cho phép tap vào kết quả search
        Timer(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _showResults = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    // Detach search controller
    widget.searchController?._detach();
    
    // Only dispose controller if it's internal (not external)
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Public method để parent set text mà không trigger search
  void setText(String text) {
    _isProgrammaticChange = true;
    _controller.text = text;
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _isProgrammaticChange = false;
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      final customers = await CustomerService.searchCustomers(query);
      if (mounted) {
        setState(() {
          _searchResults = customers;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
        print('Error searching customers: $e');
      }
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _isSelecting = true; // Set flag trước khi gọi callback
      _showResults = false;
      _searchResults.clear();
    });
    
    // Don't set _controller.text here - let parent handle it
    // This prevents double text setting
    
    widget.onCustomerSelected(customer);
    _focusNode.unfocus();
    
    // Reset flag after a short delay to ensure parent has processed
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: const InputDecoration(
              labelText: 'Tên *',
              hintText: 'Nhập ít nhất 3 ký tự để tìm kiếm...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              suffixIcon: Icon(Icons.search),
            ),
            validator: widget.validator,
            onChanged: (value) {
              // Notify parent về text change
              widget.onTextChanged?.call(value);
              
              // Skip search logic nếu đang trong quá trình select customer hoặc programmatic change
              if (_isSelecting || _isProgrammaticChange) {
                return;
              }
              
              if (value.isEmpty) {
                setState(() {
                  _showResults = false;
                  _searchResults.clear();
                });
                return;
              }

              if (value.length < 3) {
                setState(() {
                  _showResults = false;
                  _searchResults.clear();
                });
                return;
              }

              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 1500), () {
                _performSearch(value);
              });
            },
          ),
        ),
        if (_showResults) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isSearching
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Không tìm thấy khách hàng nào',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final customer = _searchResults[index];
                          return ListTile(
                            onTap: () => _selectCustomer(customer),
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                customer.fullName.isNotEmpty
                                    ? customer.fullName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            title: Text(
                              customer.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (customer.email.isNotEmpty)
                                  Text(
                                    customer.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (customer.billingPhone.isNotEmpty)
                                  Text(
                                    customer.billingPhone,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ],
    );
  }
}
