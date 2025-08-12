import 'package:flutter/material.dart';
import 'package:store_manager/models/offline_cart.dart';
import 'package:store_manager/services/offline_cart_service.dart';

class CartProvider extends ChangeNotifier {
  OfflineCart? offlineCart;
  bool isLoading = false;

  Future<void> initialize() async {
    await OfflineCartService.initialize();
    await getCart();
  }

  Future<void> getCart() async {
    try {
      isLoading = true;
      notifyListeners();
      
      offlineCart = await OfflineCartService.getCart();
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItemToCart({
    required int productId,
    required String name,
    required String price,
    required int quantity,
    String? imageUrl,
    String? description,
  }) async {
    try {
      final item = OfflineCartItem(
        productId: productId,
        name: name,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
        description: description,
        addedAt: DateTime.now(),
      );
      
      // Chỉ cập nhật qua service để tránh duplicate
      await OfflineCartService.addItem(item);
      
      // Sau đó load lại từ storage để đồng bộ state
      await getCart();
    } catch (e) {
      print('Error adding item to cart: $e');
      // Nếu lỗi thì load lại từ storage
      await getCart();
    }
  }

  Future<void> updateItemQuantity(int productId, int quantity) async {
    try {
      // Chỉ cập nhật qua service để tránh duplicate
      await OfflineCartService.updateItemQuantity(productId, quantity);
      
      // Sau đó load lại từ storage để đồng bộ state
      await getCart();
    } catch (e) {
      print('Error updating item quantity: $e');
      // Nếu lỗi thì load lại từ storage
      await getCart();
    }
  }

  Future<void> updateItemPrice(int productId, String newPrice) async {
    try {
      // Cập nhật giá trực tiếp qua service để giữ nguyên thứ tự
      await OfflineCartService.updateItemPrice(productId, newPrice);
      
      // Sau đó load lại từ storage để đồng bộ state
      await getCart();
    } catch (e) {
      print('Error updating item price: $e');
      // Nếu lỗi thì load lại từ storage
      await getCart();
    }
  }

  Future<void> removeItem(int productId) async {
    try {
      // Chỉ cập nhật qua service để tránh duplicate
      await OfflineCartService.removeItem(productId);
      
      // Sau đó load lại từ storage để đồng bộ state
      await getCart();
    } catch (e) {
      print('Error removing item: $e');
      // Nếu lỗi thì load lại từ storage
      await getCart();
    }
  }

  Future<void> clearCart() async {
    try {
      // Chỉ cập nhật qua service để tránh duplicate
      await OfflineCartService.clearCart();
      
      // Sau đó load lại từ storage để đồng bộ state
      await getCart();
    } catch (e) {
      print('Error clearing cart: $e');
      // Nếu lỗi thì load lại từ storage
      await getCart();
    }
  }

  // Getters cho cart
  int get itemCount => offlineCart?.itemsCount ?? 0;
  String get totalPrice => offlineCart?.totalPrice ?? '0';
  List<OfflineCartItem> get offlineItems => offlineCart?.items ?? [];

  // Helper methods
  bool hasItem(int productId) {
    return offlineCart?.hasItem(productId) ?? false;
  }

  OfflineCartItem? getItem(int productId) {
    return offlineCart?.getItem(productId);
  }

  @override
  void dispose() {
    OfflineCartService.close();
    super.dispose();
  }
}