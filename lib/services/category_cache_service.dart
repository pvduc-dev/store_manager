import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/category.dart';

class CategoryCacheService {
  static const String _storageKey = 'cached_categories';

  /// Lấy categories từ cache
  static Future<List<Category>?> getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = prefs.getString(_storageKey);
      
      if (categoriesJson == null) {
        return null;
      }
      
      final List<dynamic> categoriesList = json.decode(categoriesJson);
      final categories = categoriesList.map((json) => Category.fromJson(json)).toList();
      
      return categories;
      
    } catch (e) {
      return null;
    }
  }

  /// Lưu categories vào cache
  static Future<void> cacheCategories(List<Category> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesJson = json.encode(categories.map((category) => category.toJson()).toList());
      await prefs.setString(_storageKey, categoriesJson);
    } catch (e) {
      // Lỗi khi lưu categories vào cache
    }
  }

  /// Xóa cache categories
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Lỗi khi xóa cache
    }
  }
}
