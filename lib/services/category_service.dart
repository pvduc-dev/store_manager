import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';

class CategoryService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String consumerKey = 'ck_1234567890abcdef';
  static const String consumerSecret = 'cs_1234567890abcdef';

  /// Lấy danh sách tất cả danh mục sản phẩm
  static Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/categories?per_page=100'),
        headers: {
          'Authorization': 'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Không thể lấy danh mục: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy danh mục: $e');
    }
  }

  /// Lấy danh mục theo ID
  static Future<Category> getCategoryById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/categories/$id'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Category.fromJson(data);
      } else {
        throw Exception('Không thể lấy danh mục: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi lấy danh mục: $e');
    }
  }

  /// Tạo danh mục mới
  static Future<Category> createCategory({
    required String name,
    String? description,
    String? slug,
    int? parent,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/categories'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'description': description ?? '',
          'slug': slug ?? name.toLowerCase().replaceAll(' ', '-'),
          'parent': parent,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Category.fromJson(data);
      } else {
        throw Exception('Không thể tạo danh mục: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi tạo danh mục: $e');
    }
  }

  /// Cập nhật danh mục
  static Future<Category> updateCategory({
    required int id,
    String? name,
    String? description,
    String? slug,
    int? parent,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/products/categories/$id'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (slug != null) 'slug': slug,
          if (parent != null) 'parent': parent,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Category.fromJson(data);
      } else {
        throw Exception('Không thể cập nhật danh mục: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Lỗi khi cập nhật danh mục: $e');
    }
  }

  /// Xóa danh mục
  static Future<bool> deleteCategory(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/categories/$id'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Lỗi khi xóa danh mục: $e');
    }
  }
}
