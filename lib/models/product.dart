class Product {
  final int id;
  final String name;
  final String description;
  final List<MetaData> metaData;
  final List<ProductImage> images;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.metaData,
    required this.images,
  });

  Product copyWith({
    int? id,
    String? name,
    String? description,
    List<MetaData>? metaData,
    List<ProductImage>? images,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      metaData: metaData ?? this.metaData,
      images: images ?? this.images,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      metaData:
          (json['meta_data'] as List?)
              ?.map((meta) => MetaData.fromJson(meta as Map<String, dynamic>))
              .toList() ??
          [],
      images:
          (json['images'] as List?)
              ?.map((e) => ProductImage.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'meta_data': metaData.map((meta) => meta.toJson()).toList(),
      'images': images.map((image) => image.toJson()).toList(),
    };
  }
}

class ProductImage {
  final int id;
  final String? src;
  final String? name;
  final String? alt;

  ProductImage({required this.id, this.src, this.name, this.alt});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      name: json['name'] ?? '',
      alt: json['alt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'src': src, 'name': name, 'alt': alt};
  }
}

class MetaData {
  final String key;
  final String value;

  MetaData({required this.key, required this.value});

  factory MetaData.fromJson(Map<String, dynamic> json) {
    return MetaData(key: json['key'] ?? '', value: json['value'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'key': key, 'value': value};
  }
}
