import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _userPhone;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userPhone => _userPhone;

  Future<void> login(String phone, String password) async {
    // TODO: Implement actual login logic
    _isAuthenticated = true;
    _userId = 'temp_user_id';
    _userPhone = phone;
    notifyListeners();
  }

  Future<void> register(String phone, String password) async {
    // TODO: Implement actual registration logic
    _isAuthenticated = true;
    _userId = 'temp_user_id';
    _userPhone = phone;
    notifyListeners();
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _userId = null;
    _userPhone = null;
    notifyListeners();
  }

  Future<void> updatePhone(String newPhone) async {
    // TODO: Implement actual phone update logic
    _userPhone = newPhone;
    notifyListeners();
  }
} 