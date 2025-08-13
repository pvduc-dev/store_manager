import 'package:dio/dio.dart';
import 'package:store_manager/models/category.dart';

class CategoryService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Category>> getCategories() async {
    final response = await Dio().get(
      '$baseUrl/products/categories?per_page=100',
      options: Options(headers: {'Authorization': basicAuth}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }
}