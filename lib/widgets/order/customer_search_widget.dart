import 'package:flutter/material.dart';
import 'package:store_manager/models/customer.dart';
import 'package:store_manager/services/customer_service.dart';
import 'dart:async';

class CustomerSearchWidget extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final Function(Customer)? onCustomerSelected;

  const CustomerSearchWidget({
    super.key,
    this.label,
    this.placeholder,
    required this.controller,
    this.prefixIcon,
    this.validator,
    this.onCustomerSelected,
  });

  @override
  State<CustomerSearchWidget> createState() => _CustomerSearchWidgetState();
}

class _CustomerSearchWidgetState extends State<CustomerSearchWidget> {
  bool _isFocused = false;
  bool _isLoading = false;
  String? _errorText;
  List<Customer> _suggestions = [];
  bool _showSuggestions = false;
  bool _hasError = false;
  String _searchQuery = '';
  Timer? _debounceTimer;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    widget.controller.removeListener(_onTextChanged);
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    
    if (_isFocused) {
      // Show suggestions when focused if we have data or need to search
      final query = widget.controller.text;
      if (query.isNotEmpty && (_suggestions.isNotEmpty || _hasError)) {
        _showSuggestionsOverlay();
      } else if (query.isNotEmpty) {
        // Trigger search if we have text but no suggestions yet
        _searchCustomers(query);
      }
    } else {
      // Hide suggestions when focus is lost
      _hideSuggestions();
      
      // Clear search state
      if (mounted) {
        setState(() {
          _hasError = false;
          _searchQuery = '';
        });
      }
    }
  }

  void _onTextChanged() {
    if (!mounted) return;
    
    final query = widget.controller.text;
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      _hideSuggestions();
      if (mounted) {
        setState(() {
          _hasError = false;
          _suggestions.clear();
          _searchQuery = '';
        });
      }
      return;
    }

    // Only search if the field is focused
    if (_isFocused) {
      // Debounce search
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          _searchCustomers(query);
        }
      });
    }
  }

  Future<void> _searchCustomers(String query) async {
    if (!mounted || query.trim().isEmpty) {
      _hideSuggestions();
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _searchQuery = query;
      });
    }

    try {
      // Use real API
      final customers = await CustomerService.searchCustomers(query: query);
      
      // For testing with mock data, uncomment the line below and comment the line above:
      // final customers = await CustomerService.getMockCustomers(query: query);
      
      if (mounted) {
        setState(() {
          _suggestions = customers;
          _isLoading = false;
          _hasError = false;
        });
        
        // Only show overlay if the field is focused
        if (_isFocused) {
          _showSuggestionsOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _suggestions = [];
          _hasError = true;
        });
        // Only show overlay with error message if the field is focused
        if (_isFocused) {
          _showSuggestionsOverlay();
        }
      }
    }
  }

  void _showSuggestionsOverlay() {
    // Kiểm tra widget có còn mounted và context có còn valid không
    if (!mounted) return;
    
    _removeOverlay();
    
    try {
      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: MediaQuery.of(context).size.width - 32, // Account for padding
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 60), // Position below the input
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _buildSuggestionsContent(),
              ),
            ),
          ),
        ),
      );

      // Sử dụng addPostFrameCallback để đảm bảo context đã sẵn sàng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _overlayEntry != null) {
          try {
            Overlay.of(context).insert(_overlayEntry!);
            if (mounted) {
              setState(() {
                _showSuggestions = true;
              });
            }
          } catch (e) {
            debugPrint('Error inserting overlay: $e');
            _removeOverlay();
          }
        }
      });
    } catch (e) {
      debugPrint('Error creating overlay: $e');
      _removeOverlay();
    }
  }

  Widget _buildSuggestionsContent() {
    // Show error message if API failed
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Không tìm thấy khách hàng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Vui lòng thử lại hoặc nhập thông tin thủ công',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show "no results" message if search returned empty
    if (_suggestions.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Không tìm thấy khách hàng',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Không có kết quả cho "$_searchQuery"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Show customer list
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final customer = _suggestions[index];
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              customer.fullName.isNotEmpty 
                  ? customer.fullName[0].toUpperCase()
                  : 'C',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          title: Text(
            customer.fullName.isNotEmpty 
                ? customer.fullName 
                : 'Khách hàng #${customer.id}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customer.company.isNotEmpty)
                Text(
                  customer.company,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              if (customer.email.isNotEmpty)
                Text(
                  customer.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          onTap: () => _selectCustomer(customer),
        );
      },
    );
  }

  void _hideSuggestions() {
    _removeOverlay();
    if (mounted) {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _removeOverlay() {
    try {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    } catch (e) {
      debugPrint('Error removing overlay: $e');
      _overlayEntry = null;
    }
  }

  void _selectCustomer(Customer customer) {
    // Hide suggestions immediately
    _hideSuggestions();
    
    // Update text field
    widget.controller.text = customer.fullName;
    
    // Remove focus from input
    _focusNode.unfocus();
    
    // Clear search state
    if (mounted) {
      setState(() {
        _hasError = false;
        _suggestions.clear();
        _searchQuery = '';
      });
    }
    
    // Notify parent about selected customer
    widget.onCustomerSelected?.call(customer);
  }

  void _validateInput(String? value) {
    if (widget.validator != null && mounted) {
      setState(() {
        _errorText = widget.validator!(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // Input Container
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey[800] : Colors.white,
              border: Border.all(
                color: _getBorderColor(theme, isDark),
                width: _isFocused ? 2 : 1,
              ),
              boxShadow: _isFocused 
                  ? [
                                              BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : [
                                              BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Prefix Icon
                if (widget.prefixIcon != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      widget.prefixIcon,
                      size: 20,
                      color: _getIconColor(theme, isDark),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Text Field
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      _validateInput(value);
                    },
                    onFieldSubmitted: (value) {
                      if (_suggestions.isNotEmpty) {
                        _selectCustomer(_suggestions.first);
                      }
                    },
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                
                // Search Icon & Loading
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getIconColor(theme, isDark),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          size: 20,
                          color: _getIconColor(theme, isDark),
                        ),
                ),
              ],
            ),
          ),
          
          // Error Text
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorText!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBorderColor(ThemeData theme, bool isDark) {
    if (_errorText != null) {
      return Colors.red[400]!;
    }
    if (_isFocused) {
      return theme.primaryColor;
    }
    return isDark ? Colors.grey[600]! : Colors.grey[300]!;
  }

  Color _getIconColor(ThemeData theme, bool isDark) {
    return isDark ? Colors.grey[400]! : Colors.grey[600]!;
  }
}
