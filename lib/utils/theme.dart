import 'package:flutter/material.dart';

class ApplicationTheme with ChangeNotifier {
  static bool _darkMode = ThemeMode.system == ThemeMode.dark;

  ThemeMode currentTheme() {
    return _darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  bool get darkMode => _darkMode;

  void toggleTheme() {
    _darkMode = !_darkMode;
    notifyListeners();
  }
}
