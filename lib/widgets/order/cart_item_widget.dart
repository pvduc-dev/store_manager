import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CartItemWidget extends StatefulWidget {
  final String productName;
  final String productImageUrl;
  final double initialPrice;
  final int initialQuantity;
  final VoidCallback onDelete;
  final void Function(double price, int quantity) onUpdate;

  const CartItemWidget({
    super.key,
    required this.productName,
    required this.productImageUrl,
    required this.initialPrice,
    required this.initialQuantity,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  State<CartItemWidget> createState() => _CartItemWidgetState();
}

class _CartItemWidgetState extends State<CartItemWidget> {
  late double price;
  late int quantity;
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    price = widget.initialPrice;
    quantity = widget.initialQuantity;
    _priceController = TextEditingController(text: _formatPrice(widget.initialPrice));
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  String _formatPrice(double value) {
    // Luôn hiển thị 2 chữ số thập phân cho tiền tệ
    return value.toStringAsFixed(2);
  }

  void _notifyUpdate() => widget.onUpdate(price, quantity);

  void _increaseQuantity() {
    setState(() => quantity += 1);
    _notifyUpdate();
  }

  void _decreaseQuantity() {
    if (quantity <= 1) return;
    setState(() => quantity -= 1);
    _notifyUpdate();
  }

  void _onPriceChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() => price = 0);
      return;
    }
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return;
    setState(() => price = parsed);
    _notifyUpdate();
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc muốn xoá sản phẩm này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (shouldDelete == true) widget.onDelete();
  }

  Widget _buildImage(String url) {
    final bool isNetwork = url.startsWith('http');
    const double size = 64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: size,
        height: size,
        child: isNetwork
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder())
            : Image.asset(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _imagePlaceholder()),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.image, color: Colors.grey.shade400, size: 32),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.06),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            _buildImage(widget.productImageUrl),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: name + delete
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: _confirmDelete,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Xoá sản phẩm',
                      ),
                    ],
                  ),

                  // Price field
                  SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,2})?$')),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Nhập giá',
                        isDense: true,
                        suffixText: 'zł',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: _onPriceChanged,
                      onEditingComplete: () {
                        _priceController.text = _formatPrice(price);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Quantity controls + total
                  Row(
                    children: [
                      _circleButton(icon: Icons.remove, onTap: _decreaseQuantity),
                      const SizedBox(width: 12),
                      _quantityBox(quantity),
                      const SizedBox(width: 12),
                      _circleButton(icon: Icons.add, onTap: _increaseQuantity),
                      const Spacer(),
                      Text(
                        '${(price * quantity).toStringAsFixed(2)} zł',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.green),
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

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      height: 36,
      width: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: const BorderSide(color: Colors.blue),
          foregroundColor: Colors.blue,
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }

  Widget _quantityBox(int value) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        color: Colors.white,
      ),
      child: Text(
        '$value',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }
}


