import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/widgets/molecule/cart_item.dart';
import 'package:store_manager/widgets/molecule/product_search_box.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // Load cart data khi màn hình được khởi tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CartProvider>().getCart();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => context.push('/order/checkout'),
            icon: Icon(Icons.payment),
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cart == null || cartProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final cart = cartProvider.cart!;
          
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Giỏ hàng trống',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Thêm sản phẩm vào giỏ hàng để bắt đầu mua sắm',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: Text('Tiếp tục mua sắm'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search box để thêm sản phẩm
              ProductSearchBox(
                onSearch: (query) {
                  // TODO: Implement product search
                  print('Searching for: $query');
                },
                onAddProduct: () {
                  // TODO: Implement add product to cart
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tính năng thêm sản phẩm sẽ được implement')),
                  );
                },
              ),
              
              // Header thông tin tổng quan
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${cart.itemsCount} sản phẩm',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<CartProvider>().getCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã cập nhật giỏ hàng')),
                        );
                      },
                      child: Text(
                        'Cập nhật giỏ hàng',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Danh sách items
              Expanded(
                child: ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    
                    return CartItemWidget(
                      cartItem: item,
                      onIncrease: () {
                        // TODO: Implement increase quantity
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Increase quantity cho ${item.name}')),
                        );
                      },
                      onDecrease: () {
                        // TODO: Implement decrease quantity
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Decrease quantity cho ${item.name}')),
                        );
                      },
                      onRemove: () {
                        _removeItem(context, item);
                      },
                      onPriceEdit: (newPrice) {
                        // TODO: Implement price edit
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Update price cho ${item.name}: $newPrice')),
                        );
                      },
                      onQuantityChanged: (newQuantity) {
                        // TODO: Implement quantity change
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Số lượng ${item.name} thay đổi thành: $newQuantity')),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Footer với tổng tiền và nút thanh toán
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Tổng tiền chi tiết
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tạm tính:'),
                        Text(cart.totals.totalItems),
                      ],
                    ),
                    if (cart.totals.totalDiscount != '0') ...[
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Giảm giá:'),
                          Text(
                            '-${cart.totals.totalDiscount}',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                    if (cart.totals.totalShipping != null && cart.totals.totalShipping != '0') ...[
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí vận chuyển:'),
                          Text(cart.totals.totalShipping!),
                        ],
                      ),
                    ],
                    Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tổng cộng:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          cart.totals.totalPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    FilledButton(
                      onPressed: cart.items.isNotEmpty ? _proceedToCheckout : null,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Tiến hành thanh toán',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeItem(BuildContext context, item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có muốn xóa "${item.name}" khỏi giỏ hàng?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              try {
                await context.read<CartProvider>().removeItem(item.key);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa "${item.name}" khỏi giỏ hàng'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi xóa sản phẩm'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _proceedToCheckout() {
    // Navigate to checkout screen
    context.push('/order/checkout');
  }
}
