import 'package:flutter/widgets.dart' show StringCharacters;

/// Logical lines and user-perceived characters, including whitespace.
class DocumentStatistics {
  final int lines;
  final int words;
  final int characters;

  const DocumentStatistics({
    required this.lines,
    required this.words,
    required this.characters,
  });

  factory DocumentStatistics.fromText(String text) {
    return DocumentStatistics(
      lines: RegExp(r'\r\n|\r|\n').allMatches(text).length + 1,
      words: RegExp(r'\S+', unicode: true).allMatches(text).length,
      characters: text.characters.length,
    );
  }
}
