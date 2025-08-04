import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSelectionMode = false;
  Set<int> _selectedProductIds = <int>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          title: Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa $selectedCount sản phẩm đã chọn?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                clearSelection();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa $selectedCount sản phẩm'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
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
          : FloatingActionButton(
              onPressed: () {
                context.push('/products/add');
              },
              backgroundColor: Colors.blue,
              child: Icon(Icons.add, color: Colors.white),
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
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có sản phẩm nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        productProvider.loadProducts();
                      });
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: productProvider.products.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(productProvider.products[index]),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 12),
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
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm các sản phẩm',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              FilledButton(onPressed: () {}, child: Text('Tìm kiếm')),
            ],
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
          if (!_isSelectionMode) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text('Sắp xếp mặc định', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),

            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16),
                  SizedBox(width: 4),
                  Text('Bộ lọc', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
            SizedBox(width: 12),
          ],
          if (_isSelectionMode) Spacer(),

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
                    _isSelectionMode ? 'Hủy chọn' : 'Chọn',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          child: Row(
            children: [
              Spacer(),
              if (selectedCount > 0) ...[
                TextButton(
                  onPressed: () {
                    clearSelection();
                  },
                  child: Text(
                    'Bỏ chọn tất cả',
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
                SizedBox(width: 8),
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
                       ? 'Bỏ chọn tất cả'
                       : 'Chọn tất cả',
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                'Đã chọn $selectedCount/$totalCount sản phẩm',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Spacer(),
              Opacity(
                opacity: selectedCount > 0 ? 1.0 : 0.0,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0 ? () {
                    _showDeleteConfirmDialog();
                  } : null,
                  icon: Icon(Icons.delete, size: 18, color: Colors.white),
                  label: Text(
                    'Xóa',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildProductCard(Product product) {
    final isSelected = isProductSelected(product.id);

    return InkWell(
      onTap: () {
        if (_isSelectionMode) {
          toggleProductSelection(product.id);
        } else {
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
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                    image: product.images.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              product.images.first.src ?? '',
                            ),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              return;
                            },
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
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.metaData
                                      .where(
                                        (element) =>
                                            element.key == 'custom_price',
                                      )
                                      .firstOrNull
                                      ?.value ??
                                  '',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isSelectionMode)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  toggleProductSelection(product.id);
                },
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
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
