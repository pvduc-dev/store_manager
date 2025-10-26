import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:store_manager/models/product.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class ProductSearchCard extends StatelessWidget {
  final Product product;
  final bool showQuantityBadge;
  final int? quantityInCart;
  final VoidCallback? onTap;

  const ProductSearchCard({
    super.key,
    required this.product,
    this.showQuantityBadge = false,
    this.quantityInCart,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Product Image với ID overlay
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
                          image: product.image?.src != null
                              ? DecorationImage(
                                  alignment: Alignment.center,
                                  image: CachedNetworkImageProvider(
                                    product.image!.src!,
                                  ),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    return;
                                  },
                                )
                              : null,
                        ),
                        child: product.image?.src == null
                            ? Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Product ID overlay
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
                          '${product.id}',
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
                
                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        
                        // Price and Step trong RichText giống ProductCard
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: CurrencyFormatter.formatPLNFromString(
                                  product.price
                                ),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: ' (${product.step})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Quantity Badge (đặt ở góc trên phải, không conflict với Product ID)
            if (showQuantityBadge && quantityInCart != null && quantityInCart! > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$quantityInCart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
