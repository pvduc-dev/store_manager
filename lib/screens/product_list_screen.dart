import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/molecule/product_card.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<int> _selectedProductIds = <int>{};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    _syncSearchController(productProvider);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    if (_searchController.text.isEmpty && productProvider.isSearching) {
      productProvider.clearSearch();
    }
  }

  void _syncSearchController(ProductProvider productProvider) {
    if (productProvider.searchQuery != _searchController.text) {
      _searchController.removeListener(_onSearchChanged);
      _searchController.text = productProvider.searchQuery;
      _searchController.addListener(_onSearchChanged);
    }
  }

  void _performSearch() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      productProvider.searchProducts(query);
    } else {
      productProvider.clearSearch();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.loadMoreProducts();
    }
  }

  bool isProductSelected(int productId) =>
      _selectedProductIds.contains(productId);

  void toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void clearSelection() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  void selectAll(List<Product> products) {
    setState(() {
      _selectedProductIds.addAll(products.map((p) => p.id));
    });
  }

  void _showDeleteConfirmDialog() {
    final selectedCount = _selectedProductIds.length;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Potwierdź usunięcie'),
          content: Text(
            'Czy na pewno chcesz usunąć $selectedCount wybranych produktów?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Anuluj', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                context.read<ProductProvider>().deleteProducts(
                  _selectedProductIds.toList(),
                );
                clearSelection();
                setState(() {
                  _isSelectionMode = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usunięto $selectedCount produktów'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Usuń', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSortBottomSheet(
    BuildContext context,
    ProductProvider productProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sortuj według',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              ...ProductSortOption.values.map((option) {
                final isSelected = productProvider.sortOption == option;
                return ListTile(
                  title: Text(option.displayName),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    if (!isSelected) {
                      await productProvider.changeSortOption(option);
                    }
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _isSelectionMode
          ? null
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    return Stack(
                      children: [
                        FloatingActionButton(
                          onPressed: () {
                            context.push('/cart');
                          },
                          backgroundColor: Colors.orange,
                          heroTag: 'cart',
                          child: Icon(Icons.shopping_cart, color: Colors.white),
                        ),
                        if (cartProvider.itemCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '${cartProvider.itemCount}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: () {
                    context.push('/products/add');
                  },
                  backgroundColor: Colors.blue,
                  heroTag: 'add',
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!_isSelectionMode) _buildHeader(),
            _buildFilterBar(),
            if (_isSelectionMode) _buildSelectionBar(),
            Expanded(
              child: Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (productProvider.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            productProvider.isSearching
                                ? Icons.search_off
                                : Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            productProvider.isSearching
                                ? 'Nie znaleziono produktów'
                                : 'Nie ma jeszcze produktów',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (productProvider.isSearching) ...[
                            SizedBox(height: 8),
                            Text(
                              'Spróbuj wyszukać z innymi słowami kluczowymi',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                          SizedBox(height: 8),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      _searchController.removeListener(_onSearchChanged);
                      _searchController.clear();
                      _searchController.addListener(_onSearchChanged);
                      productProvider.clearSearch();
                      await productProvider.loadProducts(refresh: true);
                    },
                    child: Stack(
                      children: [
                        GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: _isSelectionMode ? 1.05 : 0.88,
                              ),
                          itemCount: productProvider.products.length,
                          itemBuilder: (context, index) {
                            return ProductCard(
                              product: productProvider.products[index],
                              isSelectionMode: _isSelectionMode,
                              isSelected: isProductSelected(productProvider.products[index].id),
                              onSelectionTap: () => toggleProductSelection(productProvider.products[index].id),
                            );
                          },
                        ),
                        if (productProvider.isLoadingMore)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: CircularProgressIndicator(
                                  strokeCap: StrokeCap.round,
                                  strokeWidth: 4.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
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
                            hintText: 'Wyszukaj produkty',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            suffixIcon: Consumer<ProductProvider>(
                              builder: (context, productProvider, child) {
                                if (productProvider.isSearching) {
                                  return IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey[600],
                                    ),
                                    onPressed: () {
                                      _searchController.removeListener(
                                        _onSearchChanged,
                                      );
                                      _searchController.clear();
                                      _searchController.addListener(
                                        _onSearchChanged,
                                      );
                                      productProvider.clearSearch();
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

  Widget _buildFilterBar() {
    if (_isSelectionMode) return SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              return GestureDetector(
                onTap: () => _showSortBottomSheet(context, productProvider),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        productProvider.sortOption.displayName,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              );
            },
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                if (!_isSelectionMode) {
                  clearSelection();
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    'Wybierz',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildSelectionBar() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final selectedCount = _selectedProductIds.length;
        final totalCount = productProvider.products.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSelectionMode = false;
                    clearSelection();
                  });
                },
                child: Row(
                  children: [
                    Text(
                      'Anuluj wybór',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              if (selectedCount > 0) ...[
                TextButton(
                  onPressed: () {
                    clearSelection();
                  },
                  child: Text(
                    'Odznacz wszystko',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              ],
              TextButton(
                onPressed: () {
                  if (selectedCount == totalCount) {
                    clearSelection();
                  } else {
                    selectAll(productProvider.products);
                  }
                },
                child: Text(
                  selectedCount == totalCount
                      ? 'Odznacz wszystko'
                      : 'Zaznacz wszystko',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionBottomBar() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final selectedCount = _selectedProductIds.length;
        final totalCount = productProvider.products.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                offset: Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Wybrano $selectedCount/$totalCount produktów',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Opacity(
                opacity: selectedCount > 0 ? 1.0 : 0.0,
                child: TextButton.icon(
                  onPressed: selectedCount > 0
                      ? () {
                          _showDeleteConfirmDialog();
                        }
                      : null,
                  icon: Icon(Icons.delete, size: 18, color: Colors.red),
                  label: Text(
                    'Usuń',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
