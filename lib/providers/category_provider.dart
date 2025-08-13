import 'package:flutter/material.dart';
import 'package:store_manager/models/category.dart';
import 'package:store_manager/services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> categories = [];

  Future<void> fetchCategories() async {
    categories = await CategoryService.getCategories();
    notifyListeners();
  }
}