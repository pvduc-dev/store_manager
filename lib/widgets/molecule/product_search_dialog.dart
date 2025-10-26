import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/models/product.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/services/product_service.dart';
import 'package:store_manager/widgets/molecule/product_search_card.dart';
import 'dart:async';

class ProductSearchDialog extends StatefulWidget {
  const ProductSearchDialog({super.key});

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  
  List<Product> _searchResults = [];
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
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreResults();
    }
  }

  Future<void> _loadMoreResults() async {
    if (_isLoadingMore || !_hasMoreResults || _lastQuery.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Load more products from next page
      final nextPage = _currentPage + 1;
      final newProducts = await ProductService.searchProducts(
        _lastQuery, 
        page: nextPage,
      );

      setState(() {
        if (newProducts.isEmpty) {
          _hasMoreResults = false;
        } else {
          _searchResults.addAll(newProducts);
          _currentPage = nextPage;
        }
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas ładowania więcej: $e')),
        );
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _lastQuery = '';
      });
      return;
    }

    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isSearching = true;
      _searchResults.clear();
      _currentPage = 1;
      _hasMoreResults = true;
    });

    try {
      final products = await ProductService.searchProducts(query);
      if (mounted) {
        setState(() {
          _searchResults = products;
          _isSearching = false;
          _hasMoreResults = products.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd podczas wyszukiwania: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[300]!, width: 1.0),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: const TextStyle(fontSize: 16),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 1000), () {
                      _performSearch(value);
                    });
                  },
                  onSubmitted: (value) => _performSearch(value),
                  decoration: InputDecoration(
                    hintText: 'Wyszukaj produkty...',
                    hintStyle: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: _buildSearchResults(),
    );
  }


  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_lastQuery.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Wyszukaj produkty',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wprowadź nazwę produktu, aby wyszukać i dodać do koszyka',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nie znaleziono produktów',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spróbuj wyszukać z innymi słowami kluczowymi',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        return RefreshIndicator(
          onRefresh: () => _performSearch(_lastQuery),
          child: Stack(
            children: [
              GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  final existingItem = cartProvider.getItem(product.id);
                  
                  return ProductSearchCard(
                    product: product,
                    showQuantityBadge: true,
                    quantityInCart: existingItem?.quantity,
                    onTap: () => Navigator.of(context).pop(product.id),
                  );
                },
              ),
              
              // Loading more indicator
              if (_isLoadingMore)
                const Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
