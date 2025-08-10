import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

  // NumberFormat cho việc format số tiền
  final NumberFormat _numberFormat = NumberFormat('#,##0', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    // Load cart when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().getCart();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSearchController();
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

  void _syncSearchController() {
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
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
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final productProvider = Provider.of<ProductProvider>(
        context,
        listen: false,
      );
      productProvider.loadMoreProducts();
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProductIds.clear();
      }
      // Exit shopping mode when entering selection mode
      if (_isSelectionMode) {
        _isShoppingMode = false;
      }
    });
  }

  void _toggleShoppingMode() {
    setState(() {
      _isShoppingMode = !_isShoppingMode;
      // Exit selection mode when entering shopping mode
      if (_isShoppingMode) {
        _isSelectionMode = false;
        _selectedProductIds.clear();
      }
    });

    // Load cart data when entering shopping mode
    if (_isShoppingMode) {
      context.read<CartProvider>().getCart();
    }
  }



  /// Format số tiền với dấu phẩy ngăn cách
  String _formatPrice(String price) {
    try {
      // Remove currency suffix and parse
      final cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
      final numericPrice = double.tryParse(cleanPrice) ?? 0;
      return _numberFormat.format(numericPrice);
    } catch (e) {
      return price; // Return original if formatting fails
    }
  }

  Future<void> _addToCart(int productId, {int quantity = 1}) async {
    final cartProvider = context.read<CartProvider>();

    // Kiểm tra xem sản phẩm đã có trong giỏ chưa
    if (cartProvider.isProductInCart(productId.toString())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sản phẩm đã có trong giỏ hàng'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      await cartProvider.addItemToCart(
        productId.toString(),
        quantity: quantity,
      );

      // Force notify để đảm bảo UI được update
      cartProvider.forceNotify();

      // Không hiển thị thông báo thành công để tránh spam UI
      // if (mounted) {
      //   print('ProductListScreen: Add to cart successful, showing snackbar');
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'Đã thêm ${quantity > 1 ? '$quantity sản phẩm' : 'sản phẩm'} vào giỏ hàng',
      //       ),
      //       backgroundColor: Colors.green,
      //       duration: const Duration(seconds: 2),
      //       action: SnackBarAction(
      //         label: 'Xem giỏ hàng',
      //         textColor: Colors.white,
      //         onPressed: () => context.push('/cart'),
      //       ),
      //     ),
      //   );
      // }


    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi khi thêm sản phẩm';

        // Xử lý các loại lỗi cụ thể
        if (e.toString().contains('Network error')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại.';
        } else if (e.toString().contains('401') ||
            e.toString().contains('403')) {
          errorMessage = 'Lỗi xác thực. Vui lòng đăng nhập lại.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Sản phẩm không tồn tại.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Lỗi server. Vui lòng thử lại sau.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _addToCart(productId, quantity: quantity),
            ),
          ),
        );
      }
    }
  }

  Future<void> _updateCartQuantity(String cartItemKey, int newQuantity) async {
    if (newQuantity <= 0) {
      // Khi quantity = 0, xóa sản phẩm khỏi giỏ hàng
      try {
        await context.read<CartProvider>().removeItem(cartItemKey);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa sản phẩm khỏi giỏ hàng'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa sản phẩm: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      return;
    }

    try {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.updateItemQuantity(cartItemKey, newQuantity);

      // Force notify để đảm bảo UI được update
      cartProvider.forceNotify();

      // Không hiển thị thông báo cho việc cập nhật số lượng để tránh spam
      // Chỉ hiển thị khi có lỗi
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi khi cập nhật số lượng';

        // Xử lý các loại lỗi cụ thể
        if (e.toString().contains('Network error')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Sản phẩm không tồn tại trong giỏ hàng.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _updateCartQuantity(cartItemKey, newQuantity),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeFromCart(String cartItemKey) async {
    try {
      await context.read<CartProvider>().removeItem(cartItemKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa sản phẩm khỏi giỏ hàng'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi khi xóa sản phẩm';

        // Xử lý các loại lỗi cụ thể
        if (e.toString().contains('Network error')) {
          errorMessage = 'Lỗi kết nối mạng. Vui lòng thử lại.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Sản phẩm không tồn tại trong giỏ hàng.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Thử lại',
              textColor: Colors.white,
              onPressed: () => _removeFromCart(cartItemKey),
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearCart() async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa giỏ hàng'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa toàn bộ sản phẩm trong giỏ hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await context.read<CartProvider>().clearCart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa toàn bộ giỏ hàng'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa giỏ hàng: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

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
                context.read<ProductProvider>().deleteProducts(
                  _selectedProductIds.toList(),
                );
                _clearSelection();
                setState(() => _isSelectionMode = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa $selectedCount sản phẩm'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
      },
    );
  }

  Future<void> _refreshProducts() async {
    _searchController.removeListener(_onSearchChanged);
    _searchController.clear();
    _searchController.addListener(_onSearchChanged);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );
    productProvider.clearSearch();
    await productProvider.loadProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: (_isSelectionMode || _isShoppingMode)
          ? null
          : FloatingActionButton(
              onPressed: () => context.push('/products/add'),
              backgroundColor: Colors.blue,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      bottomNavigationBar: _isSelectionMode
          ? _buildSelectionBottomBar()
          : _isShoppingMode
          ? _buildShoppingBottomBar()
          : null,
      body: SafeArea(
        child: Column(
          children: [
            if (!_isSelectionMode && !_isShoppingMode) _buildHeader(),
            _buildFilterBar(),
            if (_isSelectionMode) _buildSelectionBar(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
    );
  }

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
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => _performSearch(),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm các sản phẩm',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
                suffixIcon: Consumer<ProductProvider>(
                  builder: (context, productProvider, child) {
                    if (productProvider.isSearching) {
                      return IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[600]),
                        onPressed: () {
                          _searchController.removeListener(_onSearchChanged);
                          _searchController.clear();
                          _searchController.addListener(_onSearchChanged);
                          productProvider.clearSearch();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (!_isSelectionMode && !_isShoppingMode) ...[
            _buildSortButton(),
            const Spacer(),
            const SizedBox(width: 12),
          ],
          if (_isSelectionMode || _isShoppingMode) const Spacer(),
          if (!_isShoppingMode) _buildSelectionToggle(),
          if (!_isSelectionMode) ...[
            if (!_isShoppingMode) const SizedBox(width: 12),
            _buildShoppingToggle(),
          ],
          const SizedBox(width: 12),
        ],
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

  Widget _buildSelectionToggle() {
    return GestureDetector(
      onTap: _toggleSelectionMode,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              _isSelectionMode ? 'Hủy chọn' : 'Chọn',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              const Spacer(),
              if (selectedCount > 0) ...[
                TextButton(
                  onPressed: _clearSelection,
                  child: const Text(
                    'Bỏ chọn tất cả',
                    style: TextStyle(color: Colors.red, fontSize: 14),
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
                child: Text(
                  selectedCount == totalCount
                      ? 'Bỏ chọn tất cả'
                      : 'Chọn tất cả',
                  style: const TextStyle(color: Colors.blue, fontSize: 14),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
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
              Opacity(
                opacity: selectedCount > 0 ? 1.0 : 0.0,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0
                      ? _showDeleteConfirmDialog
                      : null,
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
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShoppingBottomBar() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final itemCount = cartProvider.itemCount;
        final totalPrice = cartProvider.totalPrice;

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
              // Cart info
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

              // Total price
              Text(
                'Tổng cộng',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                '${_formatPrice(totalPrice)} zł',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              const Spacer(),

              // Action buttons
              if (itemCount > 0) ...[
                // View cart button
                FilledButton(
                  onPressed: cartProvider.isLoading
                      ? null
                      : () => context.push('/cart'),
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
                ),
              ] else ...[
                Text(
                  'Giỏ hàng trống',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.products.isEmpty) {
          return _buildEmptyState(productProvider);
        }

        return RefreshIndicator(
          onRefresh: _refreshProducts,
          child: MasonryGridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
            ),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            itemCount:
                productProvider.products.length +
                (productProvider.hasMoreData ? 2 : 0),
            itemBuilder: (context, index) {
              if (index >= productProvider.products.length) {
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
                } else {
                  return const SizedBox.shrink();
                }
              }

              return _buildProductCard(productProvider.products[index]);
            },
          ),
        );
      },
    );
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
          Text(
            productProvider.isSearching
                ? 'Không tìm thấy sản phẩm nào'
                : 'Chưa có sản phẩm nào',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          if (productProvider.isSearching) ...[
            const SizedBox(height: 8),
            Text(
              'Thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          _toggleProductSelection(product.id);
        } else if (!_isShoppingMode) {
          context.push('/products/${product.id}');
        }
      },
      child: Stack(
        children: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
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
            ),
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

  Widget _buildProductImage(Product product) {
    return Container(
      height: _isShoppingMode ? 100 : 120, // Giảm height khi shopping mode
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: Colors.grey[200],
        image: product.images.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(
                  product.images.first.src ?? '',
                ),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) => null,
              )
            : null,
      ),
      child: product.images.isEmpty
          ? Center(
              child: Icon(
                Icons.image_not_supported,
                color: Colors.grey[400],
                size: 40,
              ),
            )
          : null,
    );
  }

  Widget _buildProductInfo(Product product) {
    final customPrice =
        product.metaData
            .where((element) => element.key == 'custom_price')
            .firstOrNull
            ?.value ??
        '';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _isShoppingMode ? 8.0 : 12.0,  // left
        _isShoppingMode ? 8.0 : 12.0,  // top
        _isShoppingMode ? 8.0 : 12.0,  // right
        _isShoppingMode ? 4.0 : 8.0,   // bottom - giảm để gần với shopping controls
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            product.name,
            style: TextStyle(
              fontSize: _isShoppingMode ? 13 : 14, 
              fontWeight: FontWeight.w600,
            ),
            maxLines: _isShoppingMode ? 2 : 3,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: _isShoppingMode ? 6 : 8),

          Text(
            '${_formatPrice(customPrice)} zł',
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

  Widget _buildShoppingControls(Product product) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final productId = product.id.toString();
        final isInCart = cartProvider.isProductInCart(productId);

        if (!isInCart) {
          return Container(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), // Giảm top padding
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cartProvider.isLoading
                    ? null
                    : () => _addToCart(product.id),
                style: FilledButton.styleFrom(
                  backgroundColor: cartProvider.isLoading
                      ? Colors.grey
                      : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: cartProvider.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
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

        // Product is in cart, show quantity controls
        final cartItem = cartProvider.cart!.items.firstWhere(
          (item) => item.id.toString() == productId,
        );
        final quantity = cartItem.quantity;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), // Giảm top padding
          child: Column(
            children: [
              // Quantity controls row
              Row(
                children: [
                  // Decrease button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cartProvider.isLoading
                          ? Colors.grey[300]
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: cartProvider.isLoading
                          ? null
                          : () =>
                                _updateCartQuantity(cartItem.key, quantity - 1),
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.remove,
                        size: 16,
                        color: cartProvider.isLoading
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ),

                  // Quantity display
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: cartProvider.isLoading
                            ? Colors.grey[100]
                            : Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cartProvider.isLoading
                              ? Colors.grey[300]!
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: cartProvider.isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            )
                          : Text(
                              quantity.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue,
                              ),
                            ),
                    ),
                  ),

                  // Increase button
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: cartProvider.isLoading
                          ? Colors.grey[400]
                          : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: cartProvider.isLoading
                          ? null
                          : () =>
                                _updateCartQuantity(cartItem.key, quantity + 1),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // Item total price
              const SizedBox(height: 4),
              Text(
                'Tổng: ${_formatPrice(cartItem.totals.lineTotal)} ${cartItem.totals.currencySuffix}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
