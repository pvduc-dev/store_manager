import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';
import 'dart:math' as math;

class CartItemWidget extends StatefulWidget {
  final CartItem cartItem;
  final VoidCallback? onRemove;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final Function(int)? onQuantityChanged;

  const CartItemWidget({
    Key? key,
    required this.cartItem,
    this.onRemove,
    this.onIncrease,
    this.onDecrease,
    this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.cartItem.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: _formatUnitPriceForDisplay(
        widget.cartItem.totals.lineTotal,
        widget.cartItem.quantity,
        widget.cartItem.totals.currencyMinorUnit,
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Cập nhật text khi widget thay đổi
    if (oldWidget.cartItem.totals.lineTotal != widget.cartItem.totals.lineTotal ||
        oldWidget.cartItem.quantity != widget.cartItem.quantity) {
      _priceController.text = _formatUnitPriceForDisplay(
        widget.cartItem.totals.lineTotal,
        widget.cartItem.quantity,
        widget.cartItem.totals.currencyMinorUnit,
      );
    }
    if (oldWidget.cartItem.quantity != widget.cartItem.quantity) {
      _quantityController.text = widget.cartItem.quantity.toString();
    }
  }

  String _formatPriceForDisplay(String priceInMinorUnits, int currencyMinorUnit) {
    final int priceInCents = int.tryParse(priceInMinorUnits) ?? 0;
    final double priceInUnits = priceInCents / math.pow(10, currencyMinorUnit);
    return priceInUnits.toStringAsFixed(2);
  }

  /// Format giá đơn vị (giá của 1 sản phẩm)
  String _formatUnitPriceForDisplay(String lineTotal, int quantity, int currencyMinorUnit) {
    final int totalInCents = int.tryParse(lineTotal) ?? 0;
    final int unitPriceInCents = quantity > 0 ? totalInCents ~/ quantity : 0;
    final double unitPriceInUnits = unitPriceInCents / math.pow(10, currencyMinorUnit);
    return unitPriceInUnits.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh sản phẩm
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: widget.cartItem.images.isNotEmpty 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.cartItem.images.first.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.image_not_supported, color: Colors.grey);
                      },
                    ),
                  )
                : Icon(Icons.image_not_supported, color: Colors.grey),
            ),
            SizedBox(width: 12),
            
            // Thông tin sản phẩm
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cartItem.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.cartItem.sku.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(
                      'SKU: ${widget.cartItem.sku}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  SizedBox(height: 8),
                  
                  // TextField giá (chỉ đọc, không thể chỉnh sửa)
                  Container(
                    width: 100,
                    child: TextField(
                      controller: _priceController,
                      readOnly: true, // Chỉ đọc, không thể chỉnh sửa
                      enableInteractiveSelection: false, // Tắt khả năng chọn text
                      showCursor: false, // Ẩn con trỏ
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        isDense: true,
                        hintText: 'Giá',
                        suffixText: widget.cartItem.totals.currencySymbol,
                        filled: true,
                        fillColor: Colors.grey[100], // Màu nền để thể hiện readonly
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Điều khiển số lượng và xóa
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Điều khiển số lượng
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              int currentQty = int.tryParse(_quantityController.text) ?? 1;
                              if (currentQty > 1) {
                                _quantityController.text = (currentQty - 1).toString();
                                if (widget.onDecrease != null) {
                                  widget.onDecrease!();
                                }
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            width: 60,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              onSubmitted: (value) {
                                int? newQty = int.tryParse(value);
                                if (newQty != null && newQty > 0) {
                                  if (widget.onQuantityChanged != null) {
                                    widget.onQuantityChanged!(newQty);
                                  }
                                  // Không hiển thị toast ở đây nữa, để CartScreen handle việc hiển thị toast sau khi API thành công
                                } else {
                                  // Reset to original value if invalid
                                  _quantityController.text = widget.cartItem.quantity.toString();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Số lượng không hợp lệ'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              onChanged: (value) {
                                // Validate input on change
                                int? newQty = int.tryParse(value);
                                if (newQty == null || newQty < 1) {
                                  // Don't allow invalid values, but don't reset immediately
                                }
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              int currentQty = int.tryParse(_quantityController.text) ?? 1;
                              _quantityController.text = (currentQty + 1).toString();
                              if (widget.onIncrease != null) {
                                widget.onIncrease!();
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 20,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Nút xóa
                      InkWell(
                        onTap: () {
                          if (widget.onRemove != null) {
                            widget.onRemove!();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
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
}