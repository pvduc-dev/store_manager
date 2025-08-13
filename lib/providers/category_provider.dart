import 'package:flutter/foundation.dart';
import '../models/category.dart' as product_category;
import '../services/category_service.dart';

class CategoryProvider with ChangeNotifier {
  List<product_category.Category> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<product_category.Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Lấy danh sách tất cả danh mục
  Future<void> fetchCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _categories = await CategoryService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
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

  /// Tạo danh mục mới
  Future<bool> addCategory({
    required String name,
    String? description,
    String? slug,
    int? parent,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final newCategory = await CategoryService.createCategory(
        name: name,
        description: description,
        slug: slug,
        parent: parent,
      );

      _categories.add(newCategory);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Cập nhật danh mục
  Future<bool> updateCategory({
    required int id,
    String? name,
    String? description,
    String? slug,
    int? parent,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedCategory = await CategoryService.updateCategory(
        id: id,
        name: name,
        description: description,
        slug: slug,
        parent: parent,
      );

      final index = _categories.indexWhere((category) => category.id == id);
      if (index != -1) {
        _categories[index] = updatedCategory;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa danh mục
  Future<bool> deleteCategory(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await CategoryService.deleteCategory(id);
      if (success) {
        _categories.removeWhere((category) => category.id == id);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Xóa lỗi
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Kiểm tra xem có danh mục nào không
  bool get hasCategories => _categories.isNotEmpty;

  /// Lấy số lượng danh mục
  int get categoryCount => _categories.length;
}
