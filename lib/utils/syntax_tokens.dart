import 'package:flutter/material.dart';

class SyntaxToken {
  final int start;
  final int end;
  final int kind; // string, comment, keyword, number
  const SyntaxToken(this.start, this.end, this.kind);
}

class SyntaxTokens {
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

  static List<SyntaxToken> parse(String text, String? language) {
    if (language == null) return const [];
    if (language == 'markdown') {
      final pattern = RegExp(r'^#{1,6}\s.*$|\[[^\]]+\]\([^)]+\)|\*\*[^*]+\*\*|\*[^*]+\*',
          multiLine: true);
      return pattern.allMatches(text).map((match) =>
          SyntaxToken(match.start, match.end, 2)).toList();
    }
    final strings = [r'"(?:\\.|[^"\\])*"', r"'(?:\\.|[^'\\])*'"].join('|');
    final comments = switch (language) {
      'python' || 'yaml' => r'#[^\r\n]*',
      'javascript' || 'dart' => r'//[^\r\n]*|/\*[\s\S]*?\*/',
      _ => r'(?!)',
    };
    final keywords = switch (language) {
      'python' => 'def|class|if|else|elif|for|while|return|import|from|as|try|except|finally|with|lambda|yield|True|False|None|and|or|not|in|is|pass|raise',
      'javascript' => 'const|let|var|function|class|if|else|for|while|return|import|export|from|async|await|new|try|catch|throw|true|false|null|undefined',
      'dart' => 'class|final|const|var|void|if|else|for|while|return|import|export|async|await|new|try|catch|throw|true|false|null|extends|required',
      _ => 'true|false|null|yes|no',
    };
    final pattern = RegExp('($strings)|($comments)|(\\b(?:$keywords)\\b)|(\\b\\d+(?:\\.\\d+)?\\b)',
        multiLine: true);
    return pattern.allMatches(text).map((match) {
      final kind = match.group(1) != null ? 0 : match.group(2) != null ? 1 :
          match.group(3) != null ? 2 : 3;
      return SyntaxToken(match.start, match.end, kind);
    }).toList();
  }

  static Color color(int kind, ColorScheme scheme) => switch (kind) {
    0 => scheme.secondary,
    1 => scheme.onSurfaceVariant,
    2 => scheme.primary,
    _ => scheme.tertiary,
  };
}
