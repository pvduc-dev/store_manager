import 'package:flutter/material.dart';
import 'package:store_manager/models/offline_cart.dart';
import 'package:store_manager/utils/currency_formatter.dart';

class OfflineCartItemWidget extends StatefulWidget {
  final OfflineCartItem item;
  final Function(int) onQuantityChanged;
  final Function(String) onPriceChanged;
  final VoidCallback onRemove;

  const OfflineCartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onRemove,
  });

  @override
  State<OfflineCartItemWidget> createState() => _OfflineCartItemWidgetState();
}

class _OfflineCartItemWidgetState extends State<OfflineCartItemWidget> {
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late FocusNode _priceFocusNode;
  late FocusNode _quantityFocusNode;
  
  // Lưu giá trị gốc để reset khi validation thất bại
  late String _originalPrice;
  late int _originalQuantity;

  @override
  void initState() {
    super.initState();
    _originalPrice = widget.item.price;
    _originalQuantity = widget.item.quantity;
    
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _priceController = TextEditingController(text: widget.item.price.toString());
    
    _priceFocusNode = FocusNode();
    _quantityFocusNode = FocusNode();
    
    // Lắng nghe khi mất focus để validate
    _priceFocusNode.addListener(_onPriceFocusChanged);
    _quantityFocusNode.addListener(_onQuantityFocusChanged);
  }

  @override
  void didUpdateWidget(OfflineCartItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Cập nhật controller và original values khi widget.item thay đổi
    if (oldWidget.item.quantity != widget.item.quantity) {
      _originalQuantity = widget.item.quantity;
      _quantityController.text = widget.item.quantity.toString();
    }
    
    if (oldWidget.item.price != widget.item.price) {
      _originalPrice = widget.item.price;
      _priceController.text = widget.item.price.toString();
    }
  }

  @override
  void dispose() {
    _priceFocusNode.removeListener(_onPriceFocusChanged);
    _quantityFocusNode.removeListener(_onQuantityFocusChanged);
    _priceFocusNode.dispose();
    _quantityFocusNode.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onPriceFocusChanged() {
    if (!_priceFocusNode.hasFocus) {
      // Khi mất focus, validate giá trị
      final priceText = _priceController.text.trim();
      final price = double.tryParse(priceText);
      
      if (price == null || price <= 0) {
        // Giá trị không hợp lệ, reset về giá gốc
        _priceController.text = _originalPrice;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Giá không hợp lệ. Đã reset về giá gốc.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Giá trị hợp lệ, cập nhật original value và gọi callback
        _originalPrice = priceText;
        widget.onPriceChanged(priceText);
      }
    }
  }

  void _onQuantityFocusChanged() {
    if (!_quantityFocusNode.hasFocus) {
      // Khi mất focus, validate số lượng
      final quantityText = _quantityController.text.trim();
      final quantity = int.tryParse(quantityText);
      
      if (quantity == null || quantity <= 0) {
        // Số lượng không hợp lệ, reset về số lượng gốc
        _quantityController.text = _originalQuantity.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Số lượng không hợp lệ. Đã reset về số lượng gốc.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Số lượng hợp lệ, cập nhật original value và gọi callback
        _originalQuantity = quantity;
        widget.onQuantityChanged(quantity);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Hình ảnh sản phẩm
                if (widget.item.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.item.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                
                const SizedBox(width: 12),
                
                // Thông tin sản phẩm
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (widget.item.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.item.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Nút xóa
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Xóa sản phẩm',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Số lượng và giá
            Row(
              children: [
                // Số lượng
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số lượng',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Nút giảm
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.horizontal(left: Radius.circular(4)),
                            ),
                            child: IconButton(
                              onPressed: () {
                                final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
                                if (currentQuantity > 1) {
                                  final newQuantity = currentQuantity - 1;
                                  _quantityController.text = newQuantity.toString();
                                  _originalQuantity = newQuantity; // Cập nhật giá trị gốc
                                  widget.onQuantityChanged(newQuantity);
                                }
                              },
                              icon: Icon(Icons.remove, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                          ),
                          // Ô nhập số lượng
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _quantityController,
                                focusNode: _quantityFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                // Bỏ onChanged, chỉ validate khi mất focus
                              ),
                            ),
                          ),
                          // Nút tăng
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                            ),
                            child: IconButton(
                              onPressed: () {
                                final currentQuantity = int.tryParse(_quantityController.text) ?? 0;
                                final newQuantity = currentQuantity + 1;
                                _quantityController.text = newQuantity.toString();
                                _originalQuantity = newQuantity; // Cập nhật giá trị gốc
                                widget.onQuantityChanged(newQuantity);
                              },
                              icon: Icon(Icons.add, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Giá
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giá',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _priceController,
                          focusNode: _priceFocusNode,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          // Bỏ onChanged, chỉ validate khi mất focus
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Tổng giá của item
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatPLN(widget.item.totalPrice),
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
    );
  }
}
