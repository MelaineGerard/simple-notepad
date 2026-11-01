import 'package:flutter/material.dart';

class SyntaxToken {
  final int start;
  final int end;
  final int kind;
  const SyntaxToken(this.start, this.end, this.kind);
}

class SyntaxTokens {
  static const maxHighlightCharacters = 200000;

  static String? languageForPath(String? path) {
    final extension = path?.split('.').last.toLowerCase();
    return switch (extension) {
      'py' => 'python',
      'js' || 'jsx' || 'ts' || 'tsx' => 'javascript',
      'json' => 'json',
      'yaml' || 'yml' => 'yaml',
      'md' || 'markdown' => 'markdown',
      'dart' => 'dart',
      _ => null,
    };
  }

  static bool _letter(int code) => code >= 65 && code <= 90 ||
      code >= 97 && code <= 122 || code == 95 || code == 36 || code >= 128;
  static bool _digit(int code) => code >= 48 && code <= 57;

  static List<SyntaxToken> parse(String text, String? language) {
    if (language == null || text.length > maxHighlightCharacters) return const [];
    final keywords = (switch (language) {
      'python' => 'def class if else elif for while return import from as try except finally with lambda yield True False None and or not in is pass raise',
      'javascript' => 'const let var function class if else for while return import export from async await new try catch throw true false null undefined',
      'dart' => 'class final const var void if else for while return import export async await new try catch throw true false null extends required',
      _ => 'true false null yes no',
    }).split(' ').toSet();
    final tokens = <SyntaxToken>[];
    var i = 0;
    while (i < text.length) {
      final start = i;
      final code = text.codeUnitAt(i);
      if (language == 'markdown') {
        if (code == 35 && (i == 0 || text.codeUnitAt(i - 1) == 10)) {
          final end = text.indexOf('\n', i);
          i = end < 0 ? text.length : end;
          tokens.add(SyntaxToken(start, i, 2));
        } else if (code == 96 || code == 42) {
          final marker = String.fromCharCode(code);
          final delimiter = text.startsWith(marker * 3, i) ? marker * 3 :
              text.startsWith(marker * 2, i) ? marker * 2 : marker;
          final end = text.indexOf(delimiter, i + delimiter.length);
          if (end < 0) {
            // Consume the unmatched tail once, never rescan every prefix.
            i = text.length;
          } else {
            i = end + delimiter.length;
            tokens.add(SyntaxToken(start, i, 0));
          }
        } else { i++; }
        continue;
      }
      if (code == 34 || code == 39) {
        final quote = String.fromCharCode(code);
        if (language == 'python' && text.startsWith(quote * 3, i)) {
          final end = text.indexOf(quote * 3, i + 3);
          i = end < 0 ? text.length : end + 3;
        } else {
          i++;
          while (i < text.length) {
            if (text.codeUnitAt(i) == 92) { i = (i + 2).clamp(0, text.length).toInt(); }
            else if (text.codeUnitAt(i) == code) { i++; break; }
            else if (text.codeUnitAt(i) == 10 || text.codeUnitAt(i) == 13) { break; }
            else { i++; }
          }
        }
        tokens.add(SyntaxToken(start, i, 0));
      } else if ((language == 'python' || language == 'yaml') && code == 35 ||
          (language == 'javascript' || language == 'dart') && text.startsWith('//', i)) {
        final end = text.indexOf('\n', i);
        i = end < 0 ? text.length : end;
        tokens.add(SyntaxToken(start, i, 1));
      } else if ((language == 'javascript' || language == 'dart') && text.startsWith('/*', i)) {
        final end = text.indexOf('*/', i + 2);
        i = end < 0 ? text.length : end + 2;
        tokens.add(SyntaxToken(start, i, 1));
      } else if (_letter(code)) {
        i++;
        while (i < text.length && (_letter(text.codeUnitAt(i)) || _digit(text.codeUnitAt(i)))) { i++; }
        if (keywords.contains(text.substring(start, i))) tokens.add(SyntaxToken(start, i, 2));
      } else if (_digit(code)) {
        i++;
        while (i < text.length && (_digit(text.codeUnitAt(i)) || text.codeUnitAt(i) == 46)) { i++; }
        tokens.add(SyntaxToken(start, i, 3));
      } else { i++; }
    }
    return tokens;
  }

  static Color color(int kind, ColorScheme scheme) => switch (kind) {
    0 => scheme.secondary,
    1 => scheme.onSurfaceVariant,
    2 => scheme.primary,
    _ => scheme.tertiary,
  };
}
