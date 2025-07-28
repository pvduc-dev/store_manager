import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  String? _authToken;

  get isLoggedIn => _authToken != null;

  void login(String authToken) {
    _authToken = authToken;
    notifyListeners();
  }

  void logout() {
    _authToken = null;
    notifyListeners();
  }

  Future<void> init() async {
    final storage = FlutterSecureStorage();
    final authToken = await storage.read(key: 'authToken');
    if (authToken != null) {
      _authToken = authToken;
    }
    notifyListeners();
  }
}
