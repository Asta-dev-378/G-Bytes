import 'package:flutter/material.dart';

class NavProvider extends ChangeNotifier {
  int _currentIndex = 0; // G-Zone is default

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
