import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApplicationTheme with ChangeNotifier {
  bool _darkMode = ThemeMode.system == ThemeMode.dark;
  double _fontSize = 14;

  ApplicationTheme() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? ThemeMode.system == ThemeMode.dark;
    _fontSize = prefs.getDouble('fontSize') ?? 14;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', _darkMode);
    prefs.setDouble('fontSize', _fontSize);
  }

  ThemeMode currentTheme() {
    return _darkMode ? ThemeMode.dark : ThemeMode.light;
  }

  bool get darkMode => _darkMode;

  Future<void> toggleTheme() async {
    _darkMode = !_darkMode;
    await _saveTheme();
    notifyListeners();
  }

  double get fontSize => _fontSize;

  Future<void> changeFontSize(double value) async {
    _fontSize = value;
    await _saveTheme();
    notifyListeners();
  }
}
