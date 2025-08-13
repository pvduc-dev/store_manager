import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String description;
  final String? sku;
  final List<ProductCategory> categories;
  final List<MetaData> metaData;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.sku,
    required this.categories,
    required this.metaData,
    required this.images,
  });

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? sku,
    List<ProductCategory>? categories,
    List<MetaData>? metaData,
    List<ProductImage>? images,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      categories: categories ?? this.categories,
      metaData: metaData ?? this.metaData,
      images: images ?? this.images,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Xử lý categories một cách an toàn hơn
    List<ProductCategory> categories = [];
    try {
      if (json['categories'] != null) {
        if (json['categories'] is List) {
          categories = (json['categories'] as List)
              .where((cat) => cat != null)
              .map((cat) {
                if (cat is Map<String, dynamic>) {
                  return ProductCategory.fromJson(cat);
                }
                return null;
              })
              .where((cat) => cat != null)
              .cast<ProductCategory>()
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing categories: $e');
      categories = [];
    }

    // Xử lý metaData một cách an toàn hơn
    List<MetaData> metaData = [];
    try {
      if (json['meta_data'] != null) {
        if (json['meta_data'] is List) {
          metaData = (json['meta_data'] as List)
              .where((meta) => meta != null)
              .map((meta) {
                if (meta is Map<String, dynamic>) {
                  return MetaData.fromJson(meta);
                }
                return null;
              })
              .where((meta) => meta != null)
              .cast<MetaData>()
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing meta_data: $e');
      metaData = [];
    }

    // Xử lý images một cách an toàn hơn
    List<ProductImage> images = [];
    try {
      if (json['images'] != null) {
        if (json['images'] is List) {
          images = (json['images'] as List)
              .where((img) => img != null)
              .map((img) {
                if (img is Map<String, dynamic>) {
                  return ProductImage.fromJson(img);
                }
                return null;
              })
              .where((img) => img != null)
              .cast<ProductImage>()
              .toList();
        }
      }
    } catch (e) {
      print('Error parsing images: $e');
      images = [];
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'],
      categories: categories,
      metaData: metaData,
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'meta_data': metaData.map((meta) => meta.toJson()).toList(),
      'images': images.map((image) => image.toJson()).toList(),
    };
  }

  /// Lấy SKU từ metaData nếu không có trường SKU trực tiếp
  String? get skuFromMeta {
    if (sku != null && sku!.isNotEmpty) return sku;
    
    final skuMeta = metaData.firstWhere(
      (meta) => meta.key.toLowerCase() == 'sku',
      orElse: () => MetaData(key: '', value: ''),
    );
    
    return skuMeta.value.isNotEmpty ? skuMeta.value : null;
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class ProductImage {
  final int id;
  final String? src;
  final String? name;
  final String? alt;

  ProductImage({required this.id, this.src, this.name, this.alt});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    try {
      return ProductImage(
        id: json['id'] ?? 0,
        src: json['src'] ?? '',
        name: json['name'] ?? '',
        alt: json['alt'] ?? '',
      );
    } catch (e) {
      print('Error parsing ProductImage: $e');
      // Trả về image mặc định nếu có lỗi
      return ProductImage(
        id: 0,
        src: '',
        name: '',
        alt: '',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'src': src, 'name': name, 'alt': alt};
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class MetaData {
  final String key;
  final String value;

  MetaData({required this.key, required this.value});

  factory MetaData.fromJson(Map<String, dynamic> json) {
    try {
      return MetaData(key: json['key'] ?? '', value: json['value'] ?? '');
    } catch (e) {
      print('Error parsing MetaData: $e');
      // Trả về metadata mặc định nếu có lỗi
      return MetaData(key: '', value: '');
    }
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value};
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String? slug;

  ProductCategory({
    required this.id,
    required this.name,
    this.slug,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    try {
      return ProductCategory(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        slug: json['slug'],
      );
    } catch (e) {
      print('Error parsing ProductCategory: $e');
      // Trả về một category mặc định nếu có lỗi
      return ProductCategory(
        id: 0,
        name: 'Unknown Category',
        slug: 'unknown',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
