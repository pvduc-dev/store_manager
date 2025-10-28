import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/models/product.dart' as product_models;
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/providers/product_provider.dart';
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

  Future<void> _addToCart(product_models.Product product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      
      final existingItem = cartProvider.getItem(product.id);

      if (existingItem != null) {
        await cartProvider.updateItemQuantity(
          product.id,
          existingItem.quantity + 1,
        );
      } else {
        String price = product.price;
        int stepQuantity = int.tryParse(product.step) ?? 1;

        await cartProvider.addItemToCart(
          productId: product.id,
          name: product.name,
          price: price,
          quantity: stepQuantity,
          imageUrl: product.image?.src,
          description: '',  // Description không còn có trong model mới
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas dodawania produktu: $e'),
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

  Future<void> _removeFromCart(product_models.Product product) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cartProvider = context.read<CartProvider>();
      final existingItem = cartProvider.getItem(product.id);

      if (existingItem != null) {
        if (existingItem.quantity > 1) {
          await cartProvider.updateItemQuantity(
            product.id,
            existingItem.quantity - 1,
          );
        } else {
          await cartProvider.removeItem(product.id);
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
    final productProvider = context.watch<ProductProvider>();
    final isLoadingProduct = productProvider.isLoadingProduct(widget.product.id);
    final isUpdatingProduct = productProvider.isUpdatingProduct(widget.product.id);
    
    // Get the latest product data from provider to ensure UI reflects updates
    final currentProduct = productProvider.getProductById(widget.product.id) ?? widget.product;
    
    return InkWell(
      onTap: () {
        if (isLoadingProduct || isUpdatingProduct) {
          // Không cho phép tap vào loading/updating product
          return;
        }
        if (widget.isSelectionMode) {
          widget.onSelectionTap();
        } else {
          context.push('/products/${currentProduct.id}/detail');
        }
      },
      child: Stack(
        children: [
          Container(
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
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          color: Colors.grey[200],
                          image: currentProduct.image?.src != null
                              ? DecorationImage(
                                  alignment: Alignment.center,
                                  image: CachedNetworkImageProvider(
                                    currentProduct.image!.src!,
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    return;
                                  },
                                )
                              : null,
                        ),
                        child: currentProduct.image?.src == null
                            ? Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${currentProduct.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentProduct.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.formatPLNFromString(
                                  currentProduct.price
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' (${currentProduct.step})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        
                        if (!widget.isSelectionMode)
                          Consumer<CartProvider>(
                            builder: (context, cartProvider, child) {
                              final existingItem = cartProvider.getItem(currentProduct.id);
                              final quantityInCart = existingItem?.quantity ?? 0;

                              if (quantityInCart == 0) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 24,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _addToCart(currentProduct),
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
                                            'Dodaj',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                );
                              } else {
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : () => _removeFromCart(currentProduct),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.remove, size: 12),
                                      ),
                                    ),
                                    
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
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                    
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : () => _addToCart(currentProduct),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.add, size: 12),
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
          
          if (widget.isSelectionMode && !isLoadingProduct && !isUpdatingProduct)
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: widget.onSelectionTap,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.isSelected ? Colors.blue : Colors.white,
                    border: Border.all(
                      color: widget.isSelected ? Colors.blue : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ),
            ),
          
          // Loading overlay (for new products)
          if (isLoadingProduct)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.blue,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Đang tạo...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Updating overlay (for updating products)
          if (isUpdatingProduct)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.orange,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Đang cập nhật...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
