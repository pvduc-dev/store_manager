import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String consumerKey =
      'ck_e9a2ac84a523b06df41f743cad854c4c268d4d1';
  static const String consumerSecret =
      'cs_a3be7b8f5a85e98be41d17505eee1875f1e8e76b';

  static String get _basicAuth {
    final credentials = '$consumerKey:$consumerSecret';
    return 'Basic $credentials';
  }

  static Future<Product?> getProductDetail(int productId) async {
    try {
      final response = await Dio().get(
        '$baseUrl/products/$productId',
        options: Options(
          headers: {
            'Authorization':
                'Basic Y2tfZTlhMmFjODRhNTIzYjA2ZGY0MWY3NDNjYWQ4NTRjNGNjMjY4ZDRkMTpjc19hM2JlN2I4ZjVhODVlOThiZTQxZDE3NTA1ZWVlMTg3NWYxZThlNzZi',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(response.data);
      } else {
        print('Error fetching product: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching product: $e');
      return null;
    }
  }

  static Future<bool> updateProduct(
    int productId,
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    // Upload image first if provided
    if (imageFile != null) {
      try {
        final imageBytes = await imageFile.readAsBytes();
        final fileName = imageFile.path.split('/').last;

        final imageUploadResponse = await Dio().post(
          'https://kochamtoys.pl/wp-json/wp/v2/media',
          options: Options(
            headers: {
              'Authorization': 'Basic cGhhcHZuOlBoYXBEdXlAMjAyNQ==',
              'Content-Type': 'image/jpeg',
              'Content-Disposition': 'attachment; filename="$fileName"',
            },
          ),
          data: Stream.fromIterable(imageBytes.map((e) => [e])),
        );

        if (imageUploadResponse.statusCode == 201) {
          // Add image ID to product data
          data['images'] = [
            {'id': imageUploadResponse.data['id']},
          ];
        } else {
          print('Error uploading image: ${imageUploadResponse.statusCode}');
          return false;
        }
      } catch (e) {
        if (e is DioException) {
          print('DioException: ${e.response?.data}');
        }
        print('Exception while uploading image: $e');
        return false;
      }
    }
    try {
      final response = await Dio().put(
        '$baseUrl/products/$productId',
        options: Options(
          headers: {
            'Authorization':
                'Basic Y2tfZTlhMmFjODRhNTIzYjA2ZGY0MWY3NDNjYWQ4NTRjNGNjMjY4ZDRkMTpjc19hM2JlN2I4ZjVhODVlOThiZTQxZDE3NTA1ZWVlMTg3NWYxZThlNzZi',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error updating product: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception while updating product: $e');
      return false;
    }
  }
}
