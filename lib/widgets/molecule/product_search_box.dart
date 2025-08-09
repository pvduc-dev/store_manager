import 'package:flutter/material.dart' hide MetaData;
import 'package:provider/provider.dart';
import 'package:store_manager/models/product.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/services/product_service.dart';
import 'dart:async';

class ProductSearchBox extends StatefulWidget {
  final Function(String) onSearch;

  const ProductSearchBox({super.key, required this.onSearch});

  @override
  State<ProductSearchBox> createState() => _ProductSearchBoxState();
}

class _ProductSearchBoxState extends State<ProductSearchBox> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;
  String _lastQuery = '';
  List<Product> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _showResults = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isSearching = true;
      _showResults = true;
    });

    try {
      // Gọi API trực tiếp thông qua ProductService
      final products = await ProductService.searchProducts(query);
      setState(() {
        _searchResults = products;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi tìm kiếm: $e')));
      }
    }
  }

  void _addToCart(Product product) async {
    try {
      final cartProvider = context.read<CartProvider>();

      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItem = cartProvider.getItem(product.id);

      if (existingItem != null) {
        // Nếu đã có thì tăng số lượng lên 1
        await cartProvider.updateItemQuantity(
          product.id,
          existingItem.quantity + 1,
        );
      } else {
        // Lần đầu tiên thêm sản phẩm - sử dụng giá trị PACZKA làm số lượng mặc định
        String price = product.metaData.firstWhere((meta) => meta.key == 'custom_price').value;

        // Lấy giá trị PACZKA từ metadata
        String paczkaValue = product.metaData
            .firstWhere(
              (meta) => meta.key == 'paczka',
              orElse: () => MetaData(key: 'paczka', value: '1'),
            )
            .value;
        
        // Chuyển đổi PACZKA thành số nguyên, mặc định là 1 nếu không parse được
        int paczkaQuantity = int.tryParse(paczkaValue) ?? 1;

        await cartProvider.addItemToCart(
          productId: product.id,
          name: product.name,
          price: price,
          quantity: paczkaQuantity, // Sử dụng giá trị PACZKA thay vì 1
          imageUrl: product.images.isNotEmpty ? product.images.first.src : null,
          description: product.description,
        );
      }

      // Clear search after adding
      if (mounted) {
        _controller.clear();
        setState(() {
          _showResults = false;
          _searchResults.clear();
        });
      }
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Tìm sản phẩm để thêm vào giỏ hàng:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: 'Nhập tên sản phẩm...',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _showResults = false;
                          _searchResults.clear();
                        });
                      },
                      icon: const Icon(Icons.clear, size: 18),
                    )
                  : null,
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                setState(() {
                  _showResults = false;
                  _searchResults.clear();
                });
                return;
              }

              if (_debounce?.isActive ?? false) _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 2000), () {
                _performSearch(value);
              });
            },
          ),
          if (_showResults) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[300]!),
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
                          'Không tìm thấy sản phẩm nào',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  : Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final product = _searchResults[index];
                            final existingItem = cartProvider.getItem(product.id);
                            
                            return ListTile(
                              onTap: () => _addToCart(product),
                              leading: product.images.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        product.images.first.src ?? '',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Icon(
                                              Icons.image,
                                              size: 20,
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.image, size: 20),
                                    ),
                              title: Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    product.metaData
                                        .firstWhere(
                                          (meta) => meta.key == 'custom_price',
                                          orElse: () =>
                                              MetaData(key: 'custom_price', value: '0'),
                                        )
                                        .value,
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                  if (existingItem != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Trong giỏ: ${existingItem.quantity}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.add_shopping_cart),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
