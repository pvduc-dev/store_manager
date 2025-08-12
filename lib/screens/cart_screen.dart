import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/cart.dart';
import '../models/product.dart' as product_model;

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Map để lưu trữ TextEditingController cho từng sản phẩm
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, FocusNode> _priceFocusNodes = {};

  @override
  void initState() {
    super.initState();
    // Khởi tạo giỏ hàng khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().initialize();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // Dispose tất cả controllers và focus nodes
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var focusNode in _priceFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Khởi tạo controller cho một sản phẩm
  void _initializeController(CartItem item) {
    if (!_priceControllers.containsKey(item.product.id)) {
      _priceControllers[item.product.id] = TextEditingController(
        text: item.price.toStringAsFixed(0),
      );
      _priceFocusNodes[item.product.id] = FocusNode();
    } else {
      // Cập nhật text nếu giá đã thay đổi từ provider
      final currentText = _priceControllers[item.product.id]!.text;
      final currentPrice = double.tryParse(currentText) ?? 0.0;
      if ((currentPrice - item.price).abs() > 0.01) {
        _priceControllers[item.product.id]!.text = item.price.toStringAsFixed(
          0,
        );
      }
    }
  }

  // Cập nhật giá sản phẩm với validation
  void _updateItemPrice(
    CartItem item,
    String value,
    CartProvider cartProvider,
  ) {
    final newPrice = double.tryParse(value);
    if (newPrice != null && newPrice >= 0) {
      cartProvider.updateItem(item.product.id, price: newPrice);
    } else if (value.isEmpty) {
      // Nếu người dùng xóa hết, reset về giá gốc
      _priceControllers[item.product.id]?.text = item.price.toStringAsFixed(0);
    }
  }

  // Xử lý khi người dùng hoàn thành nhập giá
  void _onPriceSubmitted(
    CartItem item,
    String value,
    CartProvider cartProvider,
  ) {
    final newPrice = double.tryParse(value);
    if (newPrice != null && newPrice >= 0) {
      cartProvider.updateItem(item.product.id, price: newPrice);
      // Ẩn keyboard
      _priceFocusNodes[item.product.id]?.unfocus();

      // Hiển thị thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã cập nhật giá "${item.product.name}" thành ${newPrice.toStringAsFixed(0)} zł',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Reset về giá hiện tại nếu giá không hợp lệ
      _priceControllers[item.product.id]?.text = item.price.toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giá không hợp lệ. Vui lòng nhập số dương.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Lấy giá gốc từ meta data của sản phẩm
  double _getOriginalPrice(CartItem item) {
    final priceMeta = item.product.metaData.firstWhere(
      (meta) => meta.key == 'custom_price',
      orElse: () => product_model.MetaData(key: 'custom_price', value: '0'),
    );

    if (priceMeta.value.isNotEmpty) {
      final parsedPrice = double.tryParse(priceMeta.value);
      return parsedPrice ?? 0.0;
    }
    return 0.0;
  }

  // Reset về giá gốc
  void _resetToOriginalPrice(CartItem item, CartProvider cartProvider) {
    final originalPrice = _getOriginalPrice(item);
    cartProvider.updateItem(item.product.id, price: originalPrice);

    // Cập nhật controller
    _priceControllers[item.product.id]?.text = originalPrice.toStringAsFixed(0);

    // Hiển thị thông báo
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã khôi phục giá gốc "${item.product.name}": ${originalPrice.toStringAsFixed(0)} zł',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
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
    // Khởi tạo controller cho item này
    _initializeController(item);

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

                  // Giá sản phẩm với cải thiện UX
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hiển thị giá gốc nếu có thay đổi
                      if (_getOriginalPrice(item) != item.price)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text(
                                'Giá gốc: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '${_getOriginalPrice(item).toStringAsFixed(0)} zł',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _priceControllers[item.product.id],
                              focusNode: _priceFocusNodes[item.product.id],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.blue.shade400,
                                    width: 2,
                                  ),
                                ),
                                suffixText: 'zł',
                                hintText: 'Nhập giá',
                              ),
                              style: const TextStyle(fontSize: 14),
                              onChanged: (value) =>
                                  _updateItemPrice(item, value, cartProvider),
                              onSubmitted: (value) =>
                                  _onPriceSubmitted(item, value, cartProvider),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Nút reset về giá gốc
                          if (_getOriginalPrice(item) != item.price)
                            IconButton(
                              onPressed: () =>
                                  _resetToOriginalPrice(item, cartProvider),
                              icon: const Icon(Icons.restore),
                              color: Colors.orange,
                              tooltip: 'Khôi phục giá gốc',
                              iconSize: 20,
                            ),
                          // Nút xóa sản phẩm
                          IconButton(
                            onPressed: () => _showRemoveItemDialog(
                              context,
                              item,
                              cartProvider,
                            ),
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            tooltip: 'Xóa sản phẩm',
                          ),
                        ],
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
    // Tính toán tổng tiết kiệm
    final totalSavings = _calculateTotalSavings(cartProvider);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thông tin chi tiết
            Row(
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

                      // Hiển thị tổng tiết kiệm nếu có
                      if (totalSavings > 0)
                        Row(
                          children: [
                            Text(
                              'Giảm giá:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '-${totalSavings.toStringAsFixed(0)} zł',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Tính toán tổng tiết kiệm từ việc thay đổi giá
  double _calculateTotalSavings(CartProvider cartProvider) {
    double totalSavings = 0.0;

    for (var item in cartProvider.cart.items) {
      final originalPrice = _getOriginalPrice(item);
      if (item.price < originalPrice) {
        totalSavings += (originalPrice - item.price) * item.quantity;
      }
    }

    return totalSavings;
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
    context.push("/order/checkout");
  }
}
