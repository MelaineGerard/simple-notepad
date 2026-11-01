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
  bool _syntaxHighlighting = true;
  bool _restoreSession = true;
  late final Future<void> ready;

  ApplicationTheme() {
    ready = _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? ThemeMode.system == ThemeMode.dark;
    _fontSize = prefs.getDouble('fontSize') ?? 14;
    _syntaxHighlighting = prefs.getBool('syntaxHighlighting') ?? true;
    _restoreSession = prefs.getBool('restoreSession') ?? true;
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
    await prefs.setBool('syntaxHighlighting', _syntaxHighlighting);
    await prefs.setBool('restoreSession', _restoreSession);
  }

  ThemeMode currentTheme() => _darkMode ? ThemeMode.dark : ThemeMode.light;

  bool get darkMode => _darkMode;
  double get fontSize => _fontSize;
  EditorFont get editorFont => _editorFont;
  bool get syntaxHighlighting => _syntaxHighlighting;
  bool get restoreSession => _restoreSession;

  Future<void> changeRestoreSession(bool enabled) async {
    await ready;
    _restoreSession = enabled;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> changeSyntaxHighlighting(bool enabled) async {
    await ready;
    _syntaxHighlighting = enabled;
    notifyListeners();
    await _saveTheme();
  }

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
