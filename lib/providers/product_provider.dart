import 'package:flutter/material.dart';
import 'package:store_manager/models/product.dart' as models;
import 'package:store_manager/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  List<models.Product> _products = [];

  Map<int, models.Product> _productsMap = {};

  bool _isLoading = false;

  List<models.Product> get products => _products;

  Map<int, models.Product> get productsMap => _productsMap;

  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    final response = await ProductService.getProducts();
    _products = response;
    _productsMap = Map.fromEntries(
      response.map((product) => MapEntry(product.id, product)),
    );
    _isLoading = false;
    notifyListeners();
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
    final product = await ProductService.createProduct(data);
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

  models.Product? getProductById(int id) {
    return _productsMap[id];
  }
}
