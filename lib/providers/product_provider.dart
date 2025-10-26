import 'dart:io';
import 'package:flutter/material.dart';
import 'package:store_manager/models/product.dart' as models;
import 'package:store_manager/models/category.dart';
import 'package:store_manager/services/product_service.dart';

enum ProductSortOption {
  newest('Najnowsze', 'date', 'desc'),
  priceAsc('Cena: Od najniższej', 'price', 'asc'),
  priceDesc('Cena: Od najwyższej', 'price', 'desc');

  const ProductSortOption(this.displayName, this.orderby, this.order);
  
  final String displayName;
  final String orderby;
  final String order;
}

class ProductProvider extends ChangeNotifier {
  List<models.Product> _products = [];

  Map<int, models.Product> _productsMap = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  static const int _perPage = 48;
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.newest;
  Category? _selectedCategory;
  
  // Loading product state
  models.Product? _loadingProduct;
  int _loadingProductTempId = -1;
  
  // Updating product state
  Set<int> _updatingProductIds = <int>{};

  List<models.Product> get products {
    List<models.Product> result = List.from(_products);
    if (_loadingProduct != null) {
      result.insert(0, _loadingProduct!);
    }
    return result;
  }

  Map<int, models.Product> get productsMap => _productsMap;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;
  ProductSortOption get sortOption => _sortOption;
  Category? get selectedCategory => _selectedCategory;
  bool get hasFilter => _selectedCategory != null;
  bool get hasLoadingProduct => _loadingProduct != null;
  models.Product? get loadingProduct => _loadingProduct;
  Set<int> get updatingProductIds => _updatingProductIds;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _products.clear();
      _productsMap.clear();
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ProductService.getProducts(
        page: 1, 
        perPage: _perPage,
        orderby: _sortOption.orderby,
        order: _sortOption.order,
        categoryId: _selectedCategory?.id,
      );
      _products = response;
      _productsMap = Map.fromEntries(
        response.map((product) => MapEntry(product.id, product)),
      );
      _currentPage = 1;
      _hasMoreData = response.length == _perPage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error loading products: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      List<models.Product> response;
      
      if (_searchQuery.isNotEmpty) {
        response = await ProductService.searchProducts(
          _searchQuery, 
          page: nextPage, 
          perPage: _perPage,
          orderby: _sortOption.orderby,
          order: _sortOption.order,
          categoryId: _selectedCategory?.id,
        );
      } else {
        response = await ProductService.getProducts(
          page: nextPage, 
          perPage: _perPage,
          orderby: _sortOption.orderby,
          order: _sortOption.order,
          categoryId: _selectedCategory?.id,
        );
      }
      
      if (response.isNotEmpty) {
        _products.addAll(response);
        for (final product in response) {
          _productsMap[product.id] = product;
        }
        _currentPage = nextPage;
        _hasMoreData = response.length == _perPage;
      } else {
        _hasMoreData = false;
      }
      
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      print('Error loading more products: $e');
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchProducts(String query) async {
    _searchQuery = query.trim();
    
    if (_searchQuery.isEmpty) {
      await loadProducts(refresh: true);
      return;
    }

    _currentPage = 1;
    _hasMoreData = true;
    _products.clear();
    _productsMap.clear();
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ProductService.searchProducts(
        _searchQuery, 
        page: 1, 
        perPage: _perPage,
        orderby: _sortOption.orderby,
        order: _sortOption.order,
        categoryId: _selectedCategory?.id,
      );
      _products = response;
      _productsMap = Map.fromEntries(
        response.map((product) => MapEntry(product.id, product)),
      );
      _currentPage = 1;
      _hasMoreData = response.length == _perPage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error searching products: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      loadProducts(refresh: true);
    }
  }

  Future<void> changeSortOption(ProductSortOption sortOption) async {
    if (_sortOption != sortOption) {
      _sortOption = sortOption;
      if (_searchQuery.isNotEmpty) {
        await searchProducts(_searchQuery);
      } else {
        await loadProducts(refresh: true);
      }
    }
  }

  Future<void> filterByCategory(Category? category) async {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      if (_searchQuery.isNotEmpty) {
        await searchProducts(_searchQuery);
      } else {
        await loadProducts(refresh: true);
      }
    }
  }

  void clearCategoryFilter() {
    if (_selectedCategory != null) {
      _selectedCategory = null;
      if (_searchQuery.isNotEmpty) {
        searchProducts(_searchQuery);
      } else {
        loadProducts(refresh: true);
      }
    }
  }

  updateProduct(Map<String, dynamic> data) async {
    final product = await ProductService.updateProductLegacy(data);
    final index = _products.indexWhere((p) => p.id == product!.id);
    if (index != -1) {
      _products[index] = product!;
      _productsMap[product.id] = product;
      notifyListeners();
    }
  }

  addProduct(Map<String, dynamic> data) async {
    final product = await ProductService.createProductLegacy(data);
    if (product != null) {
      _products.insert(0, product);
      _productsMap[product.id] = product;
      notifyListeners();
    }
  }

  removeProduct(String productId) {
    _products.removeWhere((product) => product.id == productId);
    _productsMap.remove(productId);
    notifyListeners();
  }

  deleteProducts(List<int> productIds) async {
    for (var id in productIds) {
      _products.removeWhere((product) => product.id == id);
      _productsMap.remove(id);
    }
    await ProductService.deleteProduct(productIds);
    notifyListeners();
  }

  models.Product? getProductById(int id) {
    return _productsMap[id];
  }

  // Loading product methods
  void addLoadingProduct(Map<String, dynamic> productData) {
    // Tạo temporary product với ID âm để phân biệt
    _loadingProduct = models.Product(
      id: _loadingProductTempId,
      name: productData['name'] ?? '',
      price: productData['price'] ?? '0',
      step: productData['step'] ?? '1',
      warehouse: productData['warehouse'] ?? '',
      carton: productData['carton'] ?? '',
      image: productData['image'] != null ? models.ProductImage.fromJson(productData['image']) : null,
      category: productData['category'] != null ? models.ProductCategory.fromJson(productData['category']) : null,
    );
    notifyListeners();
  }

  /// Create product using new API v9 (multipart/form-data)
  Future<void> createProductWithNewAPI({
    required String name,
    required String price,
    String? step,
    String? warehouse,
    String? carton,
    String? categoryId,
    File? imageFile,
  }) async {
    try {
      final product = await ProductService.createProduct(
        name: name,
        price: price,
        step: step,
        warehouse: warehouse,
        carton: carton,
        categoryId: categoryId,
        imageFile: imageFile,
      );
      
      if (product != null) {
        // Xóa loading product
        _loadingProduct = null;
        
        // Thêm product thực vào đầu danh sách
        _products.insert(0, product);
        _productsMap[product.id] = product;
        notifyListeners();
      } else {
        _loadingProduct = null;
        notifyListeners();
      }
    } catch (e) {
      // Nếu lỗi, chỉ xóa loading product
      _loadingProduct = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Update product using new API v9 (multipart/form-data)
  Future<void> updateProductWithNewAPI({
    required int productId,
    required String name,
    required String price,
    String? step,
    String? warehouse,
    String? carton,
    String? categoryId,
    File? imageFile,
  }) async {
    // Mark product as updating
    _updatingProductIds.add(productId);
    notifyListeners();
    
    try {
      final updatedProduct = await ProductService.updateProduct(
        productId: productId,
        name: name,
        price: price,
        step: step,
        warehouse: warehouse,
        carton: carton,
        categoryId: categoryId,
        imageFile: imageFile,
      );
      
      if (updatedProduct != null) {
        // Update product in list
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = updatedProduct;
          _productsMap[productId] = updatedProduct;
        }
        
        // Remove from updating set
        _updatingProductIds.remove(productId);
        notifyListeners();
      } else {
        _updatingProductIds.remove(productId);
        notifyListeners();
      }
    } catch (e) {
      // Nếu lỗi, remove khỏi updating set
      _updatingProductIds.remove(productId);
      notifyListeners();
      rethrow;
    }
  }

  /// Legacy method - create product using JSON data (kept for backward compatibility)
  Future<void> createProductFromLoading(Map<String, dynamic> productData) async {
    try {
      final product = await ProductService.createProductLegacy(productData);
      
      if (product != null) {
        // Xóa loading product
        _loadingProduct = null;
        
        // Thêm product thực vào đầu danh sách
        _products.insert(0, product);
        _productsMap[product.id] = product;
        notifyListeners();
      } else {
        _loadingProduct = null;
        notifyListeners();
      }
    } catch (e) {
      // Nếu lỗi, chỉ xóa loading product
      _loadingProduct = null;
      notifyListeners();
      rethrow;
    }
  }

  void removeLoadingProduct() {
    if (_loadingProduct != null) {
      _loadingProduct = null;
      notifyListeners();
    }
  }

  bool isLoadingProduct(int productId) {
    return _loadingProduct != null && _loadingProduct!.id == productId;
  }

  bool isUpdatingProduct(int productId) {
    return _updatingProductIds.contains(productId);
  }
}
