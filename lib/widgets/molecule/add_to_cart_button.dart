import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/models/product.dart' as product_models;
import 'package:store_manager/providers/cart_provider.dart';

class AddToCartButton extends StatefulWidget {
  final product_models.Product product;
  final int quantity;

  const AddToCartButton({
    super.key,
    required this.product,
    this.quantity = 1,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final isInCart = cartProvider.hasItem(widget.product.id);
        
        return ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _addToCart(cartProvider),
          icon: _isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(isInCart ? Icons.check : Icons.add_shopping_cart),
          label: Text(
            isInCart ? 'Đã thêm' : 'Thêm vào giỏ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isInCart ? Colors.green : Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addToCart(CartProvider cartProvider) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Kiểm tra xem sản phẩm đã có trong giỏ hàng chưa
      final existingItem = cartProvider.getItem(widget.product.id);

      if (existingItem != null) {
        // Nếu đã có thì tăng số lượng theo widget.quantity
        await cartProvider.updateItemQuantity(
          widget.product.id,
          existingItem.quantity + widget.quantity,
        );
      } else {
        // Lần đầu tiên thêm sản phẩm - sử dụng giá trị step làm số lượng mặc định
        String price = widget.product.price;
        
        // Chuyển đổi step thành số nguyên, mặc định là 1 nếu không parse được
        int stepQuantity = int.tryParse(widget.product.step) ?? 1;
        
        await cartProvider.addItemToCart(
          productId: widget.product.id,
          name: widget.product.name,
          price: price,
          quantity: stepQuantity, // Sử dụng giá trị step
          imageUrl: widget.product.image?.src,
          description: '',  // Description không còn có trong model mới
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
}
