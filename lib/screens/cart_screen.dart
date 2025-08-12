import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Khởi tạo giỏ hàng khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isNotEmpty) {
                return IconButton(
                  onPressed: () => _showClearCartDialog(context),
                  icon: const Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Xóa tất cả giỏ hàng',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Có lỗi xảy ra',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cartProvider.error!,
                    style: TextStyle(color: Colors.red.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => cartProvider.refresh(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (cartProvider.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thêm sản phẩm vào giỏ hàng để bắt đầu mua sắm',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Tiếp tục mua sắm'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.cart.items[index];
                    return _buildCartItemCard(context, item, cartProvider);
                  },
                ),
              ),
              _buildBottomBar(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 0, top: 8, bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh sản phẩm
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.product.images.isNotEmpty
                  ? Image.network(
                      item.product.images.first.src ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        );
                      },
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
            const SizedBox(width: 16),

            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên sản phẩm
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Giá sản phẩm
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(
                            text: item.price.toString(),
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            border: OutlineInputBorder(),
                            suffixText: 'zł',
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) {
                            final newPrice = double.tryParse(value);
                            if (newPrice != null && newPrice >= 0) {
                              cartProvider.updateItem(
                                item.product.id,
                                price: newPrice,
                              );
                            }
                          },
                        ),
                      ),
                      // Nút xóa sản phẩm
                      IconButton(
                        onPressed: () =>
                            _showRemoveItemDialog(context, item, cartProvider),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        tooltip: 'Xóa sản phẩm',
                      ),
                    ],
                  ),

                  // Số lượng và tổng giá
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    runAlignment: WrapAlignment.center,
                    spacing: 4,
                    children: [
                      IconButton(
                        onPressed: item.quantity > 1
                            ? () {
                                cartProvider.updateItem(
                                  item.product.id,
                                  quantity: item.quantity - 1,
                                );
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: item.quantity > 1 ? Colors.blue : Colors.grey,
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),

                      // Hiển thị số lượng
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Nút tăng số lượng
                      IconButton(
                        onPressed: () {
                          cartProvider.updateItem(
                            item.product.id,
                            quantity: item.quantity + 1,
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: Colors.blue,
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),

                      Text(
                        '${(item.price * item.quantity).toStringAsFixed(0)} zł',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Bên trái: Thông tin tổng quan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Số lượng sản phẩm
                  Row(
                    children: [
                      Text(
                        'Số sản phẩm:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cartProvider.itemCount}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // Tổng tiền
                  Row(
                    children: [
                      Text(
                        'Tổng tiền:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${cartProvider.subtotal.toStringAsFixed(0)} zł',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                ],
              ),
            ),

            // Bên phải: Nút thanh toán
            SizedBox(
              width: 180,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _handlePayment(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Thanh toán',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text(
            'Bạn có chắc chắn muốn xóa tất cả sản phẩm trong giỏ hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<CartProvider>().clearCart();
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRemoveItemDialog(
    BuildContext context,
    CartItem item,
    CartProvider cartProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: Text(
            'Bạn có chắc chắn muốn xóa "${item.product.name}" khỏi giỏ hàng?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                cartProvider.removeItem(item.product.id);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handlePayment(BuildContext context) {
    // TODO: Implement payment logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chức năng thanh toán đang được phát triển'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
