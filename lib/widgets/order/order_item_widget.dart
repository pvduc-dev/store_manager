import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';

class OrderItemWidget extends StatelessWidget {
  final CartItem item;

  const OrderItemWidget({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.product.images.isNotEmpty ? item.product.images.first.src ?? '' : '';
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Product image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Số lượng: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                if (item.product.skuFromMeta != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.product.skuFromMeta}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Price
          Text(
            '${item.totalPrice.toStringAsFixed(2)} zł',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
