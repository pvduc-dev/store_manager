import 'dart:convert';
import 'product.dart';

class Cart {
  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double total;
  final String? couponCode;
  final double discount;

  Cart({
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.couponCode,
    this.discount = 0.0,
  });

  Cart copyWith({
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? couponCode,
    double? discount,
  }) {
    return Cart(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      couponCode: couponCode ?? this.couponCode,
      discount: discount ?? this.discount,
    );
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List?)
              ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['coupon_code'],
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'coupon_code': couponCode,
      'discount': discount,
    };
  }

  /// Thêm sản phẩm vào giỏ hàng
  Cart addItem(Product product, {int quantity = 1}) {
    final existingItemIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingItemIndex != -1) {
      // Cập nhật số lượng và giá nếu sản phẩm đã tồn tại
      final updatedItems = List<CartItem>.from(items);
      final currentItem = updatedItems[existingItemIndex];
      final newPrice = _getProductPrice(product); // Cập nhật giá từ meta_data
      
      print('Updating existing item: old price=${currentItem.price}, new price=$newPrice');
      
      updatedItems[existingItemIndex] = currentItem.copyWith(
        quantity: currentItem.quantity + quantity,
        price: newPrice, // Cập nhật giá
      );
      
      return _recalculateCart(updatedItems);
    } else {
      // Thêm sản phẩm mới
      final productPrice = _getProductPrice(product);
      print('Creating new CartItem with price: $productPrice');
      
      final newItem = CartItem(
        product: product,
        quantity: quantity,
        price: productPrice,
      );
      
      final updatedItems = [...items, newItem];
      return _recalculateCart(updatedItems);
    }
  }

  /// Cập nhật item trong giỏ hàng (số lượng và/hoặc giá)
  Cart updateItem(int productId, {int? quantity, double? price}) {
    final updatedItems = items.map((item) {
      if (item.product.id == productId) {
        // Nếu chỉ cập nhật số lượng và số lượng <= 0, xóa item
        if (quantity != null && quantity <= 0) {
          return null; // Sẽ được filter ra ngoài
        }
        
        // Cập nhật số lượng và/hoặc giá
        final updatedPrice = price ?? _getProductPrice(item.product); // Lấy giá từ meta_data nếu không truyền vào
        print('Updating item ${item.product.id}: quantity=${quantity ?? item.quantity}, old price=${item.price}, new price=$updatedPrice');
        
        return item.copyWith(
          quantity: quantity ?? item.quantity,
          price: updatedPrice,
        );
      }
      return item;
    }).where((item) => item != null).cast<CartItem>().toList();
    
    return _recalculateCart(updatedItems);
  }

  /// Cập nhật số lượng sản phẩm (giữ nguyên để tương thích ngược)
  Cart updateItemQuantity(int productId, int quantity) {
    return updateItem(productId, quantity: quantity);
  }

  /// Xóa sản phẩm khỏi giỏ hàng
  Cart removeItem(int productId) {
    final updatedItems = items.where((item) => item.product.id != productId).toList();
    return _recalculateCart(updatedItems);
  }

  /// Xóa tất cả sản phẩm
  Cart clear() {
    return Cart(
      items: [],
      subtotal: 0.0,
      tax: 0.0,
      total: 0.0,
    );
  }

  /// Lấy số lượng sản phẩm trong giỏ
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// Lấy số loại sản phẩm khác nhau
  int get uniqueItemCount => items.length;

  /// Kiểm tra giỏ hàng có trống không
  bool get isEmpty => items.isEmpty;

  /// Kiểm tra giỏ hàng có sản phẩm không
  bool get isNotEmpty => items.isNotEmpty;

  /// Tính toán lại giá trị giỏ hàng
  Cart _recalculateCart(List<CartItem> updatedItems) {
    final subtotal = updatedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final tax = subtotal * 0.1; // Giả sử thuế 10%
    final total = subtotal + tax - discount;
    
    return Cart(
      items: updatedItems,
      subtotal: subtotal,
      tax: tax,
      total: total,
      couponCode: couponCode,
      discount: discount,
    );
  }

  /// Lấy giá sản phẩm từ custom_price trong meta data
  double _getProductPrice(Product product) {
    // Debug: In ra tất cả meta data
    print('Product ${product.id} meta data:');
    for (var meta in product.metaData) {
      print('  ${meta.key}: ${meta.value}');
    }
    
    // Tìm giá từ meta data với key 'custom_price'
    final priceMeta = product.metaData.firstWhere(
      (meta) => meta.key == 'custom_price',
      orElse: () => MetaData(key: 'custom_price', value: '0'),
    );
    
    print('Found price meta: ${priceMeta.key} = ${priceMeta.value}');
    
    if (priceMeta.value.isNotEmpty) {
      final parsedPrice = double.tryParse(priceMeta.value);
      print('Parsed price: $parsedPrice');
      return parsedPrice ?? 0.0;
    }
    
    print('No custom_price found, returning 0.0');
    return 0.0; // Giá mặc định
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class CartItem {
  final Product product;
  final int quantity;
  final double price;

  CartItem({
    required this.product,
    required this.quantity,
    required this.price,
  });

  CartItem copyWith({
    Product? product,
    int? quantity,
    double? price,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as num?)?.toDouble() ?? 0.0;
    print('CartItem.fromJson: price=$price');
    
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] ?? 1,
      price: price,
    );
  }

  Map<String, dynamic> toJson() {
    print('CartItem.toJson: price=$price');
    return {
      'product': product.toJson(),
      'quantity': quantity,
      'price': price,
    };
  }

  /// Tính tổng giá của item (giá x số lượng)
  double get totalPrice => price * quantity;

  /// Kiểm tra item có hợp lệ không
  bool get isValid => quantity > 0 && price >= 0;

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
