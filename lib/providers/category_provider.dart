import 'package:flutter/foundation.dart';
import '../models/category.dart' as product_category;
import '../services/category_cache_service.dart';
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  List<product_category.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<product_category.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Lấy danh mục từ cache
  Future<void> loadCategoriesFromCache() async {
    try {
      final cachedCategories = await CategoryCacheService.getCachedCategories();
      
      if (cachedCategories != null) {
        _categories = cachedCategories;
        notifyListeners();
      }
    } catch (e) {
      // Lỗi khi load categories từ cache
    }
  }

  /// Gọi API để lấy danh mục và lưu vào cache
  Future<void> fetchCategoriesFromAPI() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final categories = await CategoryService.getCategories();
      _categories = categories;
      
      // Lưu vào cache
      await CategoryCacheService.cacheCategories(categories);
      
      _error = null;
    } catch (e) {
      _error = 'Lỗi khi lấy danh mục: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load categories (ưu tiên cache trước, sau đó gọi API nếu cần)
  Future<void> loadCategories() async {
    // Thử load từ cache trước
    await loadCategoriesFromCache();
    
    // Nếu cache trống, gọi API
    if (_categories.isEmpty) {
      await fetchCategoriesFromAPI();
    }
  }

  /// Refresh categories từ API
  Future<void> refreshCategories() async {
    await fetchCategoriesFromAPI();
  }

  /// Lấy danh mục theo ID
  product_category.Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh mục theo tên
  product_category.Category? getCategoryByName(String name) {
    try {
      return _categories.firstWhere(
        (category) => category.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Lấy danh mục con của một danh mục
  List<product_category.Category> getChildCategories(int parentId) {
    return _categories.where((category) => category.parent == parentId).toList();
  }

  /// Lấy danh mục gốc (không có parent)
  List<product_category.Category> getRootCategories() {
    return _categories.where((category) => category.parent == null || category.parent == 0).toList();
  }

  /// Kiểm tra xem có danh mục nào không
  bool get hasCategories => _categories.isNotEmpty;

  /// Lấy số lượng danh mục
  int get categoryCount => _categories.length;
}
