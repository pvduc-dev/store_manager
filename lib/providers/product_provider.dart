import 'package:flutter/material.dart';
import 'package:store_manager/models/product.dart' as models;
import 'package:store_manager/services/product_service.dart';

enum ProductSortOption {
  newest('Mới nhất', 'date', 'desc'),
  priceAsc('Giá: Thấp đến cao', 'price', 'asc'),
  priceDesc('Giá: Cao đến thấp', 'price', 'desc');

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
  static const int _perPage = 20;
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.newest;

  List<models.Product> get products => _products;

  Map<int, models.Product> get productsMap => _productsMap;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.isNotEmpty;
  ProductSortOption get sortOption => _sortOption;

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
        );
      } else {
        response = await ProductService.getProducts(
          page: nextPage, 
          perPage: _perPage,
          orderby: _sortOption.orderby,
          order: _sortOption.order,
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
    print('ProductProvider: Starting search with query: "$_searchQuery"');
    
    if (_searchQuery.isEmpty) {
      print('ProductProvider: Query is empty, loading all products');
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
      print('ProductProvider: Calling ProductService.searchProducts');
      final response = await ProductService.searchProducts(
        _searchQuery, 
        page: 1, 
        perPage: _perPage,
        orderby: _sortOption.orderby,
        order: _sortOption.order,
      );
      
      print('ProductProvider: Search response received with ${response.length} products');
      
      _products = response;
      _productsMap = Map.fromEntries(
        response.map((product) => MapEntry(product.id, product)),
      );
      _currentPage = 1;
      _hasMoreData = response.length == _perPage;
      _isLoading = false;
      
      print('ProductProvider: Search completed. Products: ${_products.length}, HasMore: $_hasMoreData');
      notifyListeners();
    } catch (e) {
      print('ProductProvider: Error searching products: $e');
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

  updateProduct(Map<String, dynamic> data) async {
    final product = await ProductService.updateProduct(data);
    final index = _products.indexWhere((p) => p.id == product!.id);
    if (index != -1) {
      _products[index] = product!;
      _productsMap[product.id] = product;
      notifyListeners();
    }
  }

  addProduct(Map<String, dynamic> data) async {
    try {
      print('ProductProvider: Adding product with categories: ${data['categories']}');
      
      final product = await ProductService.createProduct(data);
      if (product != null) {
        print('ProductProvider: Product added successfully with ID: ${product.id}');
        _products.insert(0, product);
        _productsMap[product.id] = product;
        notifyListeners();
      } else {
        print('ProductProvider: Failed to add product');
      }
    } catch (e) {
      print('ProductProvider: Error adding product: $e');
      rethrow;
    }
  }

  removeProduct(int productId) {
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
}
