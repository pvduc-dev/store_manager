import 'dart:io';
import 'package:dio/dio.dart';
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String baseUrlV9 = 'https://kochamtoys.pl/wp-json/wc/v9';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Product>> getProducts({
    int page = 1, 
    int perPage = 40,
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

  /// Upload image separately to WordPress media library
  /// Note: This method is now optional since createProduct() can handle image upload directly
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
        final imageId = imageUploadResponse.data['id'];
        return imageId;
      } else {
        print('Error uploading image: ${imageUploadResponse.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while uploading image: $e');
      if (e is DioException) {
        print('DioException: ${e.response?.data}');
      }
      return null;
    }
  }

  /// Create product using multipart/form-data (matches the CURL command format)
  /// 
  /// Example usage:
  /// ```dart
  /// final product = await ProductService.createProduct(
  ///   name: "san pham test12",
  ///   price: "513", 
  ///   step: "12",
  ///   warehouse: "BN-SOC",
  ///   imageFile: File("/path/to/image.png"),
  ///   carton: "carton test",
  ///   categoryId: "27",
  /// );
  /// ```
  /// 
  /// This matches the CURL command:
  /// ```bash
  /// curl --location 'https://kochamtoys.pl/wp-json/wc/v9/products' \
  /// --header 'Authorization: Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q' \
  /// --form 'name="san pham test12"' \
  /// --form 'price="513"' \
  /// --form 'step="12"' \
  /// --form 'warehouse="BN-SOC"' \
  /// --form 'image=@"/Users/dung.du/Downloads/chart (4).png"' \
  /// --form 'carton="carton test"' \
  /// --form 'categoryId="27"'
  /// ```
  static Future<Product?> createProduct({
    required String name,
    required String price,
    String? step,
    String? warehouse,
    File? imageFile,
    String? carton,
    String? categoryId,
  }) async {
    try {
      // Create FormData for multipart/form-data request
      final formData = FormData();
      
      // Add required fields
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('price', price));
      
      // Add optional fields
      if (step != null && step.isNotEmpty) {
        formData.fields.add(MapEntry('step', step));
      }
      if (warehouse != null && warehouse.isNotEmpty) {
        formData.fields.add(MapEntry('warehouse', warehouse));
      }
      if (carton != null && carton.isNotEmpty) {
        formData.fields.add(MapEntry('carton', carton));
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        formData.fields.add(MapEntry('categoryId', categoryId));
      }
      
      // Add image file if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        ));
      }

      final response = await Dio().post(
        '$baseUrlV9/products',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            // Don't set Content-Type - Dio will set it automatically for FormData
          },
        ),
        data: formData,
      );

      if (response.statusCode == 201) {
        return Product.fromJson(response.data);
      } else {
        print('Error creating product: ${response.statusCode}');
        print('Response data: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Exception while creating product: $e');
      if (e is DioException) {
        print('DioException: ${e.response?.data}');
      }
      return null;
    }
  }

  /// Update product using multipart/form-data (matches the CURL command format)
  /// 
  /// Example usage:
  /// ```dart
  /// final product = await ProductService.updateProduct(
  ///   productId: 3981,
  ///   name: "san pham test13",
  ///   price: "513",
  ///   step: "12",
  ///   warehouse: "BN-SOC",
  ///   carton: "carton test",
  ///   categoryId: "27",
  ///   imageFile: File("/path/to/image.png"), // Optional
  /// );
  /// ```
  /// 
  /// This matches the CURL command:
  /// ```bash
  /// curl --location 'https://kochamtoys.pl/wp-json/wc/v9/products/3981/update' \
  /// --header 'Authorization: Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q' \
  /// --form 'name="san pham test13"' \
  /// --form 'price="513"' \
  /// --form 'step="12"' \
  /// --form 'warehouse="BN-SOC"' \
  /// --form 'carton="carton test"' \
  /// --form 'categoryId="27"'
  /// ```
  static Future<Product?> updateProduct({
    required int productId,
    required String name,
    required String price,
    String? step,
    String? warehouse,
    File? imageFile,
    String? carton,
    String? categoryId,
  }) async {
    try {
      // Create FormData for multipart/form-data request
      final formData = FormData();
      
      // Add required fields
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('price', price));
      
      // Add optional fields
      if (step != null && step.isNotEmpty) {
        formData.fields.add(MapEntry('step', step));
      }
      if (warehouse != null && warehouse.isNotEmpty) {
        formData.fields.add(MapEntry('warehouse', warehouse));
      }
      if (carton != null && carton.isNotEmpty) {
        formData.fields.add(MapEntry('carton', carton));
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        formData.fields.add(MapEntry('categoryId', categoryId));
      }
      
      // Add image file if provided
      if (imageFile != null) {
        final fileName = imageFile.path.split('/').last;
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          ),
        ));
      }

      final response = await Dio().post(
        '$baseUrlV9/products/$productId/update',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            // Don't set Content-Type - Dio will set it automatically for FormData
          },
        ),
        data: formData,
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        print('Error updating product: ${response.statusCode}');
        print('Response data: ${response.data}');
        return null;
      }
    } catch (e) {
      print('Exception while updating product: $e');
      if (e is DioException) {
        print('DioException: ${e.response?.data}');
      }
      return null;
    }
  }

  /// Legacy method - create product using JSON data (kept for backward compatibility)
  @deprecated
  static Future<Product?> createProductLegacy(Map<String, dynamic> data) async {
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

  /// Legacy method - update product using JSON data (kept for backward compatibility)
  @deprecated
  static Future<Product?> updateProductLegacy(Map<String, dynamic> data) async {
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
