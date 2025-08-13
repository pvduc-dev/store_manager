import 'dart:convert';

class Category {
  final int id;
  final String name;
  final String? description;
  final String? slug;
  final int? parent;
  final int count;
  final String? image;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.slug,
    this.parent,
    required this.count,
    this.image,
  });

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? slug,
    int? parent,
    int? count,
    String? image,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      slug: slug ?? this.slug,
      parent: parent ?? this.parent,
      count: count ?? this.count,
      image: image ?? this.image,
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      slug: json['slug'],
      parent: json['parent'],
      count: json['count'] ?? 0,
      image: json['image']?['src'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'slug': slug,
      'parent': parent,
      'count': count,
      'image': image,
    };
  }

  @override
  String toString() {
    return JsonEncoder.withIndent('  ').convert(toJson());
  }
}
