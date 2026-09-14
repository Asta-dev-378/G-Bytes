import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  // 0 = Brain Hub, 1 = G-Zone (default), 2 = G-Timer
  int _currentIndex = 1;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
