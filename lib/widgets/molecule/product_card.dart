import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/models/product.dart' as product_models;
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class ProductCard extends StatefulWidget {
  final product_models.Product product;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback onSelectionTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isSelectionMode,
    required this.isSelected,
    required this.onSelectionTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isLoading = false;

  Future<void> _addToCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      
      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItem = cartProvider.getItem(widget.product.id);

      if (existingItem != null) {
        // Nếu đã có thì tăng số lượng lên 1
        await cartProvider.updateItemQuantity(
          widget.product.id,
          existingItem.quantity + 1,
        );
      } else {
        // Lần đầu tiên thêm sản phẩm - sử dụng giá trị PACZKA làm số lượng mặc định
        String price = widget.product.metaData
            .firstWhere(
              (meta) => meta.key == 'custom_price',
              orElse: () => product_models.MetaData(key: 'custom_price', value: '0'),
            )
            .value;
        
        // Lấy giá trị PACZKA từ metadata
        String paczkaValue = widget.product.metaData
            .firstWhere(
              (meta) => meta.key == 'paczka',
              orElse: () => product_models.MetaData(key: 'paczka', value: '1'),
            )
            .value;
        
        // Chuyển đổi PACZKA thành số nguyên, mặc định là 1 nếu không parse được
        int paczkaQuantity = int.tryParse(paczkaValue) ?? 1;

        await cartProvider.addItemToCart(
          productId: widget.product.id,
          name: widget.product.name,
          price: price,
          quantity: paczkaQuantity,
          imageUrl: widget.product.images.isNotEmpty ? widget.product.images.first.src : null,
          description: widget.product.description,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi thêm sản phẩm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeFromCart() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      final existingItem = cartProvider.getItem(widget.product.id);

      if (existingItem != null) {
        if (existingItem.quantity > 1) {
          // Giảm số lượng
          await cartProvider.updateItemQuantity(
            widget.product.id,
            existingItem.quantity - 1,
          );
        } else {
          // Xóa khỏi giỏ hàng
          await cartProvider.removeItem(widget.product.id);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi cập nhật sản phẩm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (widget.isSelectionMode) {
          widget.onSelectionTap();
        } else {
          context.push('/products/${widget.product.id}');
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
                color: (widget.isSelectionMode && widget.isSelected)
                    ? Colors.blue
                    : Colors.grey[300]!,
                width: (widget.isSelectionMode && widget.isSelected) ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.08),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                    image: widget.product.images.isNotEmpty
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                              widget.product.images.first.src ?? '',
                            ),
                            fit: BoxFit.cover,
                            onError: (exception, stackTrace) {
                              return;
                            },
                          )
                        : null,
                  ),
                  child: widget.product.images.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 40,
                          ),
                        )
                      : null,
                ),
                
                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.formatPLNFromString(
                            widget.product.metaData.where((element) => element.key == 'custom_price').firstOrNull?.value ?? '0'
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        
                        // Cart Action Section
                        if (!widget.isSelectionMode)
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              final existingItem = cartProvider.getItem(widget.product.id);
                              final quantityInCart = existingItem?.quantity ?? 0;

                              if (quantityInCart == 0) {
                                // Show Add to Cart button
                                return SizedBox(
                                  width: double.infinity,
                                  height: 32,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _addToCart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Thêm',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                );
                              } else {
                                // Show quantity controls
                                return Row(
                                  children: [
                                    // Decrease button
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _removeFromCart,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.remove, size: 16),
                                      ),
                                    ),
                                    
                                    // Quantity display
                                    Expanded(
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            : Text(
                                                '$quantityInCart',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    // Increase button
                                    SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _addToCart,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.add, size: 16),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Selection indicator
          if (widget.isSelectionMode)
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: widget.onSelectionTap,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? Colors.blue : Colors.white,
                    border: Border.all(
                      color: widget.isSelected ? Colors.blue : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
