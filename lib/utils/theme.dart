import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EditorFont {
  system('System (proportional)', null),
  monospace('Monospace', 'monospace');

  final String label;
  final String? family;

  const EditorFont(this.label, this.family);
}

class ApplicationTheme with ChangeNotifier {
  bool _darkMode = ThemeMode.system == ThemeMode.dark;
  double _fontSize = 14;
  EditorFont _editorFont = EditorFont.system;
  late final Future<void> ready;

  ApplicationTheme() {
    ready = _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? ThemeMode.system == ThemeMode.dark;
    _fontSize = prefs.getDouble('fontSize') ?? 14;
    final savedFont = prefs.getString('editorFont');
    _editorFont = EditorFont.values.firstWhere(
      (font) => font.name == savedFont,
      orElse: () => EditorFont.system,
    );
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('editorFont', _editorFont.name);
  }

  ThemeMode currentTheme() => _darkMode ? ThemeMode.dark : ThemeMode.light;

  bool get darkMode => _darkMode;
  double get fontSize => _fontSize;
  EditorFont get editorFont => _editorFont;

  Future<void> toggleTheme() async {
    await ready;
    _darkMode = !_darkMode;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> changeFontSize(double value) async {
    await ready;
    _fontSize = value;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> changeEditorFont(EditorFont font) async {
    await ready;
    if (font == _editorFont) return;
    _editorFont = font;
    notifyListeners();
    await _saveTheme();
  }
}
