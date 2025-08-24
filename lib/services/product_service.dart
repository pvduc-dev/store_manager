import 'dart:io';
import 'package:dio/dio.dart';
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Product>> getProducts({
    int page = 1, 
    int perPage = 100,
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
    int perPage = 100,
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
    print('📷 ProductService: Bắt đầu upload ảnh...');
    print('📁 File path: ${imageFile.path}');
    
    try {
      print('📖 Đọc bytes từ file...');
      final imageBytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      print('📎 File name: $fileName');
      print('📏 File size: ${imageBytes.length} bytes');

      print('📤 Gửi POST request upload ảnh...');
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

      print('📥 Upload response: ${imageUploadResponse.statusCode}');
      
      if (imageUploadResponse.statusCode == 201) {
        final imageId = imageUploadResponse.data['id'];
        print('✅ Upload ảnh thành công! Image ID: $imageId');
        return imageId;
      } else {
        print('❌ Lỗi upload ảnh - Status: ${imageUploadResponse.statusCode}');
        print('📋 Response data: ${imageUploadResponse.data}');
        return null;
      }
    } catch (e) {
      print('❌ Exception khi upload ảnh: $e');
      if (e is DioException) {
        print('🔍 DioException details:');
        print('  - Type: ${e.type}');
        print('  - Message: ${e.message}');
        print('  - Response: ${e.response?.data}');
        print('  - Status Code: ${e.response?.statusCode}');
      }
      return null;
    }
  }

  static Future<Product?> createProduct(Map<String, dynamic> data) async {
    print('🌐 ProductService: Bắt đầu gọi API tạo sản phẩm...');
    print('📡 URL: $baseUrl/products');
    print('📦 Data: $data');
    
    try {
      print('📤 Gửi POST request...');
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

      print('📥 Nhận được response: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        print('✅ Tạo sản phẩm thành công!');
        print('📋 Response data: ${response.data}');
        return Product.fromJson(response.data);
      } else {
        print('❌ Lỗi tạo sản phẩm - Status: ${response.statusCode}');
        print('📋 Response data: ${response.data}');
        return null;
      }
    } catch (e) {
      print('❌ Exception khi tạo sản phẩm: $e');
      if (e is DioException) {
        print('🔍 DioException details:');
        print('  - Type: ${e.type}');
        print('  - Message: ${e.message}');
        print('  - Response: ${e.response?.data}');
        print('  - Status Code: ${e.response?.statusCode}');
      }
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

  static Future<Product?> getProductById(int productId) async {
    try {
      final response = await Dio().get(
        '$baseUrl/products/$productId',
        options: Options(headers: {'Authorization': basicAuth}),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        print('Error fetching product by ID: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching product by ID: $e');
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
