import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/models/cart.dart' show CartTotals, CartItem;
import 'package:store_manager/widgets/molecule/cart_item.dart';
import 'package:store_manager/widgets/molecule/product_search_box.dart';

String _formatMoneyFromTotals(String raw, CartTotals totals) {
  final minor = totals.currencyMinorUnit;
  final intVal = int.tryParse(raw) ?? 0;
  final divisor = math.pow(10, minor);
  final value = intVal / divisor;
  final amount = value.toStringAsFixed(minor);
  final prefix = totals.currencyPrefix;
  final suffix = totals.currencySuffix;
  final symbol = totals.currencySymbol;
  if (prefix.isNotEmpty) return '$prefix$amount';
  if (suffix.isNotEmpty) return '$amount$suffix';
  return symbol.isNotEmpty ? '$amount $symbol' : amount;
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
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
            onPressed: () => _showClearCartConfirmDialog(context),
            icon: Icon(Icons.delete_sweep, color: Colors.red[600]),
            tooltip: 'Xóa hết giỏ hàng',
          ),
        ],
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.cart == null || cartProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
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
                    style: TextStyle(color: Colors.grey[500]),
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

              // Header thông tin tổng quan
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                      onPressed: () async {
                        // Xóa thông báo hiện tại nếu có
                        ScaffoldMessenger.of(context).clearSnackBars();
                        
                        // Gọi lại API giỏ hàng
                        await context.read<CartProvider>().getCart();
                      },
                      child: Text('Làm mới'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Danh sách sản phẩm
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Xóa thông báo hiện tại nếu có
                    ScaffoldMessenger.of(context).clearSnackBars();
                    
                    // Gọi lại API giỏ hàng
                    await context.read<CartProvider>().getCart();
                  },
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return CartItemWidget(
                        cartItem: item,
                        onIncrease: () async {
                          try {
                            final newQuantity = item.quantity + 1;
                            await context
                                .read<CartProvider>()
                                .updateItemQuantitySilent(item.key, newQuantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã tăng số lượng ${item.name}: $newQuantity',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi khi tăng số lượng: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onDecrease: () async {
                          try {
                            if (item.quantity > 1) {
                              final newQuantity = item.quantity - 1;
                              await context
                                  .read<CartProvider>()
                                  .updateItemQuantitySilent(item.key, newQuantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Đã giảm số lượng ${item.name}: $newQuantity',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // Nếu số lượng = 1, hiển thị thông báo
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Số lượng tối thiểu là 1'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi khi giảm số lượng: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        onRemove: () {
                          _removeItem(context, item);
                        },
                        onQuantityChanged: (newQuantity) async {
                          try {
                            await context
                                .read<CartProvider>()
                                .updateItemQuantitySilent(item.key, newQuantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Đã cập nhật số lượng ${item.name}: $newQuantity',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi khi cập nhật số lượng: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),

              // Tổng kết giỏ hàng
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Thông tin chi tiết
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng sản phẩm:'),
                        Text(
                          _formatMoneyFromTotals(
                            cart.totals.totalItems,
                            cart.totals,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    if (cart.totals.totalDiscount != '0') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Giảm giá:'),
                          Text(
                            '-${_formatMoneyFromTotals(cart.totals.totalDiscount, cart.totals)}',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                    if (cart.totals.totalShipping != null &&
                        cart.totals.totalShipping != '0') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Phí vận chuyển:'),
                          Text(
                            _formatMoneyFromTotals(
                              cart.totals.totalShipping!,
                              cart.totals,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                    ],
                    Divider(),
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
                          _formatMoneyFromTotals(
                            cart.totals.totalPrice,
                            cart.totals,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push('/order/checkout'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Thanh toán',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _removeItem(BuildContext context, CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa sản phẩm'),
        content: Text(
          'Bạn có chắc chắn muốn xóa "${item.name}" khỏi giỏ hàng?',
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Hủy')),
          TextButton(
            onPressed: () async {
              context.pop();
              
              // Kiểm tra widget có còn mounted không
              if (!mounted) return;
              
              // Hiển thị loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('Đang xóa ${item.name}...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.blue,
                ),
              );
              
              try {
                await context.read<CartProvider>().removeItem(item.key);
                
                // Kiểm tra widget có còn mounted không
                if (!mounted) return;
                
                // Xóa thông báo loading và hiển thị thành công
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa ${item.name} khỏi giỏ hàng'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                // Kiểm tra widget có còn mounted không
                if (!mounted) return;
                
                // Xóa thông báo loading và hiển thị lỗi
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi xóa sản phẩm: $e'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: Text('Xóa'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  void _showClearCartConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa hết giỏ hàng'),
        content: Text('Bạn có chắc chắn muốn xóa hết giỏ hàng?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: Text('Hủy')),
          TextButton(
            onPressed: () async {
              context.pop();
              await context.read<CartProvider>().clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã xóa hết giỏ hàng'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text('Đồng ý'),
          ),
        ],
      ),
    );
  }
}
