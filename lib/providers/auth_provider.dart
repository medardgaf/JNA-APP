import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? user;

  bool get isLoggedIn => user != null;

  String get role => user?["role"] ?? "";

  int get id => user?["id"] ?? 0;

  void setAuth(Map<String, dynamic> userData) {
    user = userData;
    notifyListeners();
  }

  void logout() {
    user = null;
    notifyListeners();
  }
}
