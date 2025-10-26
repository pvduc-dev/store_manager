import 'package:flutter/material.dart';
import 'package:store_manager/widgets/molecule/product_search_dialog.dart';

class ProductSearchBox extends StatefulWidget {
  final Function(int) onProductSelected;

  const ProductSearchBox({super.key, required this.onProductSelected});

  @override
  State<ProductSearchBox> createState() => _ProductSearchBoxState();
}

class _ProductSearchBoxState extends State<ProductSearchBox> {

  void _openSearchDialog() async {
    final int? productId = await showDialog<int>(
      context: context,
      useSafeArea: false,
      builder: (BuildContext context) {
        return const ProductSearchDialog();
      },
    );
    
    if (productId != null) {
      widget.onProductSelected(productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openSearchDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Wyszukaj produkt',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[500],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
