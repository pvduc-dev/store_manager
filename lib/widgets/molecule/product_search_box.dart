import 'package:flutter/material.dart';

class ProductSearchBox extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback? onAddProduct;
  
  const ProductSearchBox({
    super.key,
    required this.onSearch,
    this.onAddProduct,
  });

  @override
  State<ProductSearchBox> createState() => _ProductSearchBoxState();
}

class _ProductSearchBoxState extends State<ProductSearchBox> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search,
                size: 20,
                color: Colors.grey[600],
              ),
              SizedBox(width: 8),
              Text(
                'Tìm sản phẩm để thêm vào giỏ hàng:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Nhập tên sản phẩm...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                      },
                      icon: Icon(Icons.clear, size: 18),
                    )
                  : null,
            ),
            onChanged: widget.onSearch,
            onSubmitted: (value) {
              if (value.isNotEmpty && widget.onAddProduct != null) {
                widget.onAddProduct!();
              }
            },
          ),
        ],
      ),
    );
  }
}