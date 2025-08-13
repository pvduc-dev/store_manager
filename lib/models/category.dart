class Category {
  final int id;
  final String name;
  final String slug;
  final int parent;
  final String description;
  final String? image;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.parent,
    required this.description,
    this.image,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      parent: json['parent'],
      description: json['description'],
      image: json['image'],
    );
  }
}