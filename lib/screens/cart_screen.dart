import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:store_manager/providers/cart_provider.dart';
import 'package:store_manager/widgets/molecule/product_search_box.dart';
import 'package:store_manager/widgets/molecule/offline_cart_item.dart';
import 'package:store_manager/utils/currency_formatter.dart';

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
      resizeToAvoidBottomInset: false, // Ngăn không cho keyboard đẩy UI lên
      appBar: AppBar(
        title: const Text('Giỏ hàng'),
        leading: IconButton(
          onPressed: () => context.go('/products'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return _buildOfflineCart(cartProvider);
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final offlineCart = cartProvider.offlineCart;
          
          // Chỉ hiển thị footer khi có items trong cart
          if (offlineCart == null || offlineCart.items.isEmpty) {
            return const SizedBox.shrink();
          }
          
          return _buildFooter(offlineCart);
        },
      ),
    );
  }

  Widget _buildOfflineCart(CartProvider cartProvider) {
    final offlineCart = cartProvider.offlineCart;
    
    return Column(
      children: [
        // Search box để thêm sản phẩm - luôn hiển thị
        ProductSearchBox(
          onSearch: (query) {
            // TODO: Implement product search
            print('Searching for: $query');
          },
        ),
        
        // Nội dung chính của giỏ hàng
        Expanded(
          child: (offlineCart == null || offlineCart.items.isEmpty) 
            ? _buildEmptyCart()
            : _buildCartContent(offlineCart),
        ),
      ],
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Giỏ hàng trống',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sử dụng thanh tìm kiếm ở trên để thêm sản phẩm',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/products'),
            child: const Text('Xem danh sách sản phẩm'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(offlineCart) {
    return Column(
      children: [
        // Header thông tin tổng quan
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${offlineCart.items.length} mặt hàng | ${offlineCart.itemsCount} sản phẩm',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        
        // Danh sách items offline
        Expanded(
          child: ListView.builder(
            itemCount: offlineCart.items.length,
            itemBuilder: (context, index) {
              final item = offlineCart.items[index];
              
              return OfflineCartItemWidget(
                item: item,
                onQuantityChanged: (quantity) {
                  context.read<CartProvider>().updateItemQuantity(item.productId, quantity);
                },
                onPriceChanged: (price) {
                  context.read<CartProvider>().updateItemPrice(item.productId, price);
                },
                onRemove: () {
                  context.read<CartProvider>().removeItem(item.productId);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(offlineCart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tổng tiền
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatPLNFromString(offlineCart.totalPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: offlineCart.items.isNotEmpty ? _proceedToCheckout : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Tiến hành thanh toán',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _proceedToCheckout() {
    context.push('/orders/new');
  }
}
