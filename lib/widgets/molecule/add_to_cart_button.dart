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
        // Lần đầu tiên thêm sản phẩm - sử dụng giá trị PACZKA làm số lượng mặc định
        String price = widget.product.metaData.firstWhere((meta) => meta.key == 'custom_price').value;
        
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
          quantity: paczkaQuantity, // Sử dụng giá trị PACZKA thay vì widget.quantity
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
}
