import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider with ChangeNotifier {
  String? _userName;
  bool _isInitialized = false;

  String? get userName => _userName;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _userName != null && _userName!.isNotEmpty;

  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name');
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    _userName = name;
    notifyListeners();
  }

  /// Rename without logging out.
  Future<void> rename(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', trimmed);
    _userName = trimmed;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    _userName = null;
    notifyListeners();
  }
}
