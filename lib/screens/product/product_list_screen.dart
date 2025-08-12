import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/models/product.dart';
import 'package:store_manager/providers/product_provider.dart';
import 'package:store_manager/providers/cart_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSelectionMode = false;
  bool _isShoppingMode = false;
  Set<int> _selectedProductIds = <int>{};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeCart();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSearchController();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  // MARK: - Initialization Methods
  void _initializeControllers() {
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeCart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initialize();
    });
  }

  void _disposeControllers() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
  }

  // MARK: - Search Methods
  void _onSearchChanged() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (_searchController.text.isEmpty && productProvider.isSearching) {
      productProvider.clearSearch();
    }
  }

  void _syncSearchController() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    if (productProvider.searchQuery != _searchController.text) {
      _searchController.removeListener(_onSearchChanged);
      _searchController.text = productProvider.searchQuery;
      _searchController.addListener(_onSearchChanged);
    }
  }

  void _performSearch() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      productProvider.searchProducts(query);
    } else {
      productProvider.clearSearch();
    }
  }

  Future<void> _refreshProducts() async {
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);
    
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearSearch();
    await productProvider.loadProducts(refresh: true);
  }

  // MARK: - Scroll Methods
  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      productProvider.loadMoreProducts();
    }
  }

  // MARK: - Mode Toggle Methods
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProductIds.clear();
      }
      if (_isSelectionMode) {
        _isShoppingMode = false;
      }
    });
  }

  void _toggleShoppingMode() {
    setState(() {
      _isShoppingMode = !_isShoppingMode;
      if (_isShoppingMode) {
        _isSelectionMode = false;
        _selectedProductIds.clear();
      }
    });

    if (_isShoppingMode) {
      context.read<CartProvider>().refresh();
    }
  }

  // MARK: - Cart Methods
  Future<void> _addToCart(int productId, {int quantity = 1}) async {
    try {
      final productProvider = context.read<ProductProvider>();
      final product = productProvider.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Sản phẩm không tồn tại'),
      );

      final cartProvider = context.read<CartProvider>();
      await cartProvider.addToCart(product, quantity: quantity);

      if (mounted) {
        setState(() {});
        _showSuccessSnackBar('Đã thêm ${product.name} vào giỏ hàng');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Lỗi khi thêm sản phẩm: $e', () {
          _addToCart(productId, quantity: quantity);
        });
      }
    }
  }

  Future<void> _updateCartItem(int productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeCartItem(productId);
      return;
    }

    try {
      final productProvider = context.read<ProductProvider>();
      final product = productProvider.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Sản phẩm không tồn tại'),
      );
      
      final customPrice = product.metaData
          .where((element) => element.key == 'custom_price')
          .firstOrNull
          ?.value ?? '0';
      
      final price = double.tryParse(customPrice) ?? 0.0;
      
      await context.read<CartProvider>().updateItem(
        productId, 
        quantity: newQuantity,
        price: price,
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Lỗi khi cập nhật số lượng: $e', () {
          _updateCartItem(productId, newQuantity);
        });
      }
    }
  }

  Future<void> _removeCartItem(int productId) async {
    try {
      await context.read<CartProvider>().removeItem(productId);
      if (mounted) {
        setState(() {});
        _showSuccessSnackBar('Đã xóa sản phẩm khỏi giỏ hàng');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Lỗi khi xóa sản phẩm: $e', () {
          _updateCartItem(productId, 0);
        });
      }
    }
  }

  // MARK: - Selection Methods
  void _toggleProductSelection(int productId) {
    setState(() {
      if (_selectedProductIds.contains(productId)) {
        _selectedProductIds.remove(productId);
      } else {
        _selectedProductIds.add(productId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedProductIds.clear();
    });
  }

  void _selectAll(List<Product> products) {
    setState(() {
      _selectedProductIds.addAll(products.map((p) => p.id));
    });
  }

  // MARK: - Dialog Methods
  void _showDeleteConfirmDialog() {
    final selectedCount = _selectedProductIds.length;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa $selectedCount sản phẩm đã chọn?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteSelectedProducts();
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedProducts() async {
    final selectedCount = _selectedProductIds.length;
    context.read<ProductProvider>().deleteProducts(_selectedProductIds.toList());
    _clearSelection();
    setState(() => _isSelectionMode = false);
    _showSuccessSnackBar('Đã xóa $selectedCount sản phẩm');
  }

  void _showSortBottomSheet(BuildContext context, ProductProvider productProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildSortBottomSheetContent(productProvider),
    );
  }

  Widget _buildSortBottomSheetContent(ProductProvider productProvider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sắp xếp theo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...ProductSortOption.values.map((option) {
            final isSelected = productProvider.sortOption == option;
            return ListTile(
              title: Text(option.displayName),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () async {
                context.pop();
                if (!isSelected) {
                  await productProvider.changeSortOption(option);
                }
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  // MARK: - SnackBar Methods
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message, VoidCallback? retryAction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        action: retryAction != null
            ? SnackBarAction(
                label: 'Thử lại',
                textColor: Colors.white,
                onPressed: retryAction,
              )
            : null,
      ),
    );
  }

  // MARK: - Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            if (_isSelectionMode) _buildSelectionBar(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_isSelectionMode || _isShoppingMode) return null;
    
    return FloatingActionButton(
      onPressed: () => context.push('/products/add'),
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  Widget? _buildBottomNavigationBar() {
    if (_isSelectionMode) return _buildSelectionBottomBar();
    if (_isShoppingMode) return _buildShoppingBottomBar();
    return null;
  }

  // MARK: - Header Widgets
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _performSearch,
                child: const Text('Tìm kiếm'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchTextField()),
        ],
      ),
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(fontSize: 16),
      onSubmitted: (_) => _performSearch(),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm theo tên sản phẩm',
        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
        border: InputBorder.none,
        suffixIcon: _buildSearchSuffixIcon(),
      ),
    );
  }

  Widget _buildSearchSuffixIcon() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (!productProvider.isSearching) return const SizedBox.shrink();
        
        return IconButton(
          icon: Icon(Icons.clear, color: Colors.grey[600]),
          onPressed: () {
            _searchController.removeListener(_onSearchChanged);
            _searchController.clear();
            _searchController.addListener(_onSearchChanged);
            productProvider.clearSearch();
          },
        );
      },
    );
  }

  // MARK: - Filter Bar Widgets
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSortButton(),
            const SizedBox(width: 12),
            _buildSearchTypeIndicator(),
            const SizedBox(width: 12),
            _buildSelectionToggle(),
            const SizedBox(width: 12),
            _buildShoppingToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return GestureDetector(
          onTap: () => _showSortBottomSheet(context, productProvider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text(
                  productProvider.sortOption.displayName,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchTypeIndicator() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (!productProvider.isSearching) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 14, color: Colors.blue[600]),
              const SizedBox(width: 4),
              Text(
                'Tìm: ${productProvider.searchQuery}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  productProvider.clearSearch();
                },
                child: Icon(Icons.close, size: 14, color: Colors.blue[600]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionToggle() {
    return GestureDetector(
      onTap: _toggleSelectionMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isSelectionMode ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: _isSelectionMode
              ? Border.all(color: Colors.blue, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: _isSelectionMode ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _isSelectionMode ? 'Thoát chọn' : 'Chọn',
              style: TextStyle(
                fontSize: 16,
                color: _isSelectionMode ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingToggle() {
    return GestureDetector(
      onTap: _toggleShoppingMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isShoppingMode ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: _isShoppingMode
              ? Border.all(color: Colors.blue, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              size: 16,
              color: _isShoppingMode ? Colors.blue : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _isShoppingMode ? 'Thoát mua hàng' : 'Mua hàng',
              style: TextStyle(
                fontSize: 16,
                color: _isShoppingMode ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MARK: - Selection Bar Widgets
  Widget _buildSelectionBar() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final selectedCount = _selectedProductIds.length;
        final totalCount = productProvider.products.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.blue[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.blue[700],
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Chế độ chọn sản phẩm',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (selectedCount > 0) ...[
                TextButton(
                  onPressed: _clearSelection,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text(
                    'Bỏ chọn tất cả',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              TextButton(
                onPressed: () {
                  if (selectedCount == totalCount) {
                    _clearSelection();
                  } else {
                    _selectAll(productProvider.products);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  selectedCount == totalCount
                      ? 'Bỏ chọn tất cả'
                      : 'Chọn tất cả',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // MARK: - Bottom Bar Widgets
  Widget _buildSelectionBottomBar() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final selectedCount = _selectedProductIds.length;
        final totalCount = productProvider.products.length;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.blue[300]!, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Đã chọn $selectedCount/$totalCount sản phẩm',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _buildDeleteButton(selectedCount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(int selectedCount) {
    return Opacity(
      opacity: selectedCount > 0 ? 1.0 : 0.0,
      child: FilledButton.icon(
        onPressed: selectedCount > 0 ? _showDeleteConfirmDialog : null,
        icon: const Icon(Icons.delete, size: 18, color: Colors.white),
        label: const Text(
          'Xóa',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingBottomBar() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final itemCount = cartProvider.itemCount;
        final total = cartProvider.total;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey[200]!, width: 1)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                offset: const Offset(0, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              _buildCartInfo(itemCount, total),
              const Spacer(),
              _buildCartActionButton(cartProvider, itemCount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartInfo(int itemCount, double total) {
    return Row(
      children: [
        const Icon(Icons.shopping_cart, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          '$itemCount sản phẩm',
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Tổng cộng',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          '${total.toStringAsFixed(2)} zł',
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCartActionButton(CartProvider cartProvider, int itemCount) {
    if (itemCount > 0) {
      return FilledButton(
        onPressed: cartProvider.isLoading ? null : () => context.push('/cart'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          minimumSize: const Size(0, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Xem',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }
    
    return Text(
      'Giỏ hàng trống',
      style: TextStyle(color: Colors.grey[500], fontSize: 12),
    );
  }

  // MARK: - Product Grid Widgets
  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.products.isEmpty) {
          return _buildEmptyState(productProvider);
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshProducts,
                child: _buildMasonryGrid(productProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMasonryGrid(ProductProvider productProvider) {
    return MasonryGridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      itemCount: productProvider.products.length +
          (productProvider.hasMoreData ? 2 : 0),
      itemBuilder: (context, index) {
        if (index >= productProvider.products.length) {
          return _buildLoadingIndicator(productProvider, index);
        }
        return _buildProductCard(productProvider.products[index]);
      },
    );
  }

  Widget _buildLoadingIndicator(ProductProvider productProvider, int index) {
    if (index == productProvider.products.length) {
      return productProvider.isLoadingMore
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            )
          : const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(ProductProvider productProvider) {
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
          const SizedBox(height: 16),
          _buildEmptyStateText(productProvider),
          if (productProvider.isSearching) ...[
            const SizedBox(height: 8),
            _buildEmptyStateHint(),
            const SizedBox(height: 12),
            _buildViewAllProductsButton(productProvider),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyStateText(ProductProvider productProvider) {
    return Text(
      productProvider.isSearching
          ? 'Không tìm thấy sản phẩm nào với từ khóa: "${productProvider.searchQuery}"'
          : 'Chưa có sản phẩm nào',
      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmptyStateHint() {
    return Text(
      'Thử tìm kiếm với từ khóa khác hoặc xóa từ khóa để xem tất cả sản phẩm',
      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildViewAllProductsButton(ProductProvider productProvider) {
    return FilledButton(
      onPressed: () {
        _searchController.clear();
        productProvider.clearSearch();
      },
      child: const Text('Xem tất cả sản phẩm'),
    );
  }

  // MARK: - Product Card Widgets
  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return InkWell(
      onTap: () => _onProductCardTap(product),
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: _buildProductCardDecoration(isSelected),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductImage(product),
                _buildProductInfo(product),
                if (_isShoppingMode) _buildShoppingControls(product),
              ],
            ),
          ),
          if (_isSelectionMode)
            _buildSelectionIndicator(isSelected, product.id),
        ],
      ),
    );
  }

  void _onProductCardTap(Product product) {
    if (_isSelectionMode) {
      _toggleProductSelection(product.id);
    } else if (!_isShoppingMode) {
      context.push('/products/${product.id}');
    }
  }

  BoxDecoration _buildProductCardDecoration(bool isSelected) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: (_isSelectionMode && isSelected)
            ? Colors.blue
            : Colors.grey[300]!,
        width: (_isSelectionMode && isSelected) ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.08),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildProductImage(Product product) {
    return Container(
      height: _isShoppingMode ? 100 : 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.grey[200],
        image: _buildProductImageDecoration(product),
      ),
      child: _buildProductImagePlaceholder(product),
    );
  }

  DecorationImage? _buildProductImageDecoration(Product product) {
    if (product.images.isEmpty) return null;
    
    return DecorationImage(
      image: CachedNetworkImageProvider(
        product.images.first.src ?? '',
      ),
      fit: BoxFit.cover,
      onError: (exception, stackTrace) => null,
    );
  }

  Widget? _buildProductImagePlaceholder(Product product) {
    if (product.images.isNotEmpty) return null;
    
    return Center(
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[400],
        size: 40,
      ),
    );
  }

  Widget _buildProductInfo(Product product) {
    final customPrice = _getProductCustomPrice(product);
    final packa = _getProductPacka(product);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 40),
            child: Text(
              '[${product.id}] ${product.name}  ${packa.isNotEmpty ? '(${packa})' : ''}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${customPrice} zł',
            style: TextStyle(
              fontSize: _isShoppingMode ? 14 : 16,
              color: Colors.red,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getProductCustomPrice(Product product) {
    return product.metaData
        .where((element) => element.key == 'custom_price')
        .firstOrNull
        ?.value ?? '0';
  }

  String _getProductPacka(Product product) {
    return product.metaData
        .where((element) => element.key == 'packa')
        .firstOrNull
        ?.value ?? '';
  }

  Widget _buildSelectionIndicator(bool isSelected, int productId) {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: () => _toggleProductSelection(productId),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey[400]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : null,
        ),
      ),
    );
  }

  // MARK: - Shopping Controls Widgets
  Widget _buildShoppingControls(Product product) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final productId = product.id;
        final isInCart = cartProvider.cart.items.any((item) => item.product.id == productId);

        if (!isInCart) {
          return _buildAddToCartButton(product);
        }

        final cartItem = cartProvider.getCartItem(productId);
        if (cartItem == null) return const SizedBox.shrink();

        return _buildQuantityControls(product, cartItem);
      },
    );
  }

  Widget _buildAddToCartButton(Product product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () => _addToCart(product.id),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Thêm vào giỏ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(Product product, dynamic cartItem) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildQuantityButton(
                product.id,
                cartItem.quantity - 1,
                Icons.remove,
                Colors.grey[200]!,
                Colors.black87,
              ),
              _buildQuantityDisplay(cartItem.quantity),
              _buildQuantityButton(
                product.id,
                cartItem.quantity + 1,
                Icons.add,
                Colors.blue,
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tổng: ${(cartItem.totalPrice).toStringAsFixed(2)} zł',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(
    int productId,
    int newQuantity,
    IconData icon,
    Color backgroundColor,
    Color iconColor,
  ) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: () => _updateCartItem(productId, newQuantity),
        padding: EdgeInsets.zero,
        icon: Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildQuantityDisplay(int quantity) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              quantity.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
