import 'dart:io';
import 'package:dio/dio.dart';
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Product>> getProducts({
    int page = 1, 
    int perPage = 20,
    String orderby = 'date',
    String order = 'desc',
    int? categoryId,
  }) async {
    try {
      String url = '$baseUrl/products?per_page=$perPage&page=$page&orderby=$orderby&order=$order';
      if (categoryId != null) {
        url += '&category=$categoryId';
      }
      
      final response = await Dio().get(
        url,
        options: Options(headers: {'Authorization': basicAuth}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Error fetching products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception while fetching products: $e');
      return [];
    }
  }

  static Future<List<Product>> searchProducts(String query, {
    int page = 1, 
    int perPage = 20,
    String orderby = 'relevance',
    String order = 'desc',
    int? categoryId,
  }) async {
    try {
      String url = '$baseUrl/products?search=$query&per_page=$perPage&page=$page&order_by=$orderby&order=$order';
      if (categoryId != null) {
        url += '&category=$categoryId';
      }
      
      final response = await Dio().get(
        url,
        options: Options(headers: {'Authorization': basicAuth}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Error searching products: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception while searching products: $e');
      return [];
    }
  }

  static Future<int?> uploadImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;

      final imageUploadResponse = await Dio().post(
        'https://kochamtoys.pl/wp-json/wp/v2/media',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'image/jpeg',
            'Content-Disposition': 'attachment; filename="$fileName"',
          },
        ),
        data: Stream.fromIterable(imageBytes.map((e) => [e])),
      );

      if (imageUploadResponse.statusCode == 201) {
        return imageUploadResponse.data['id'];
      } else {
        print('Error uploading image: ${imageUploadResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while uploading image: $e');
      return null;
    }
  }

  static Future<Product?> createProduct(Map<String, dynamic> data) async {
    try {
      final response = await Dio().post(
        '$baseUrl/products',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 201) {
        return Product.fromJson(response.data);
      } else {
        print('Error creating product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while creating product: $e');
      return null;
    }
  }

  static Future<Product?> updateProduct(Map<String, dynamic> data) async {
    try {
      final response = await Dio().put(
        '$baseUrl/products/${data['id']}',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        print('Error updating product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while updating product: $e');
      return null;
    }
  }

  static Future<Product?> deleteProduct(List<int> productIds) async {
    try {
      final response = await Dio().post('$baseUrl/products/batch',
        data: {
          'delete': productIds,
        },
          options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        print('Error deleting product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while deleting product: $e');
      return null;
    }
  }
}
