import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:store_manager/models/product.dart';
import 'package:http/http.dart' as http;

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];

  List<Product> get products => _products;

  loadProducts() async {
    final response = await http.get(Uri.parse('https://api.example.com/products'));
    final data = jsonDecode(response.body);
    _products = data.map((product) => Product.fromJson(product)).toList();
    notifyListeners();
  }
}