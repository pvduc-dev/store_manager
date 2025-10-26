class Product {
  final int id;
  final String name;
  final String price;
  final String step;
  final String warehouse;
  final String carton;
  final ProductImage? image;
  final ProductCategory? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.step,
    required this.warehouse,
    required this.carton,
    this.image,
    this.category,
  });

  Product copyWith({
    int? id,
    String? name,
    String? price,
    String? step,
    String? warehouse,
    String? carton,
    ProductImage? image,
    ProductCategory? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      step: step ?? this.step,
      warehouse: warehouse ?? this.warehouse,
      carton: carton ?? this.carton,
      image: image ?? this.image,
      category: category ?? this.category,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? '0',
      step: json['step'] ?? '1',
      warehouse: json['warehouse'] ?? '',
      carton: json['carton'] ?? '',
      image: json['image'] != null ? ProductImage.fromJson(json['image']) : null,
      category: json['category'] != null ? ProductCategory.fromJson(json['category']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'step': step,
      'warehouse': warehouse,
      'carton': carton,
      'image': image?.toJson(),
      'category': category?.toJson(),
    };
  }
}

class ProductImage {
  final String id;
  final String? src;

  ProductImage({required this.id, this.src});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id']?.toString() ?? '0',
      src: json['src'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'src': src};
  }
}

class ProductCategory {
  final int id;
  final String name;

  ProductCategory({required this.id, required this.name});

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
