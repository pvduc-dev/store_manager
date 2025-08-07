import 'package:flutter/material.dart';
import 'package:store_manager/models/cart.dart';

class CartItemWidget extends StatefulWidget {
  final CartItem cartItem;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onRemove;
  final Function(String)? onPriceEdit;
  final Function(int)? onQuantityChanged;
  
  const CartItemWidget({
    super.key, 
    required this.cartItem,
    this.onIncrease,
    this.onDecrease,
    this.onRemove,
    this.onPriceEdit,
    this.onQuantityChanged,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late TextEditingController _priceController;
  late TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.cartItem.prices.price);
    _quantityController = TextEditingController(text: widget.cartItem.quantity.toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
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
                  
                  // TextField giá
                  Container(
                    width: 100,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                      ),
                      onSubmitted: (value) {
                        if (widget.onPriceEdit != null) {
                          widget.onPriceEdit!(value);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã thay đổi giá: $value')),
                        );
                      },
                      onChanged: (value) {
                        // Có thể thêm validation real-time nếu cần
                      },
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Đã thay đổi số lượng: $newQty')),
                                  );
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
                        onTap: widget.onRemove,
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