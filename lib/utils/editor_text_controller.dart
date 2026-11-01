import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/syntax_tokens.dart';

class EditorTextController extends TextEditingController {
  EditorTextController({super.text, String? path}) : _path = path;

  VoidCallback? revealSelection;
  String? _path;
  String _query = '';
  bool _caseSensitive = false;
  String? _tokenText;
  String? _tokenLanguage;
  List<SyntaxToken> _tokens = const [];

  set filePath(String? path) {
    if (_path == path) return;
    _path = path;
    notifyListeners();
  }

  String? get language => SyntaxTokens.languageForPath(_path);
  String get query => _query;
  bool get caseSensitive => _caseSensitive;

  void search(String query, {bool caseSensitive = false}) {
    if (_query == query && _caseSensitive == caseSensitive) return;
    _query = query;
    _caseSensitive = caseSensitive;
    notifyListeners();
  }

  List<TextRange> get matches {
    if (_query.isEmpty) return const [];
    return RegExp(RegExp.escape(_query), caseSensitive: _caseSensitive, unicode: true)
        .allMatches(text).map((match) =>
            TextRange(start: match.start, end: match.end)).toList();
  }

  int get selectedMatch => matches.indexWhere((range) =>
      range.start == selection.start && range.end == selection.end);

  void selectMatch({bool backwards = false}) {
    final found = matches;
    if (found.isEmpty) return;
    final offset = selection.isValid
        ? (backwards ? selection.start : selection.end) : 0;
    var index = backwards
        ? found.lastIndexWhere((range) => range.end <= offset)
        : found.indexWhere((range) => range.start >= offset);
    if (index < 0) index = backwards ? found.length - 1 : 0;
    selection = TextSelection(baseOffset: found[index].start, extentOffset: found[index].end);
    revealSelection?.call();
  }

  bool replaceOne(String replacement) {
    if (matches.isEmpty) return false;
    if (selectedMatch < 0) selectMatch();
    final start = selection.start;
    final end = selection.end;
    value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    revealSelection?.call();
    return true;
  }

  int replaceAll(String replacement) {
    final found = matches;
    if (found.isEmpty) return 0;
    final output = StringBuffer();
    var offset = 0;
    for (final range in found) {
      output.write(text.substring(offset, range.start));
      output.write(replacement);
      offset = range.end;
    }
    output.write(text.substring(offset));
    value = TextEditingValue(text: output.toString(),
        selection: const TextSelection.collapsed(offset: 0));
    return found.length;
  }

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style,
      required bool withComposing}) {
    // Keep Flutter's IME composing underline and range behavior intact.
    if (withComposing && value.isComposingRangeValid && !value.composing.isCollapsed) {
      return super.buildTextSpan(context: context, style: style, withComposing: true);
    }
    final scheme = Theme.of(context).colorScheme;
    final language = this.language;
    final syntaxEnabled = applicationTheme.syntaxHighlighting;
    if (syntaxEnabled && (_tokenText != text || _tokenLanguage != language)) {
      _tokenText = text;
      _tokenLanguage = language;
      _tokens = SyntaxTokens.parse(text, language);
    }
    final tokens = syntaxEnabled ? _tokens : <SyntaxToken>[];
    final found = matches;
    final boundaries = <int>{0, text.length,
      for (final token in tokens) ...[token.start, token.end],
      for (final range in found) ...[range.start, range.end],
    }.toList()..sort();
    final spans = <TextSpan>[];
    var tokenIndex = 0;
    var matchIndex = 0;
    for (var i = 0; i < boundaries.length - 1; i++) {
      final start = boundaries[i];
      final end = boundaries[i + 1];
      while (tokenIndex < tokens.length && tokens[tokenIndex].end <= start) { tokenIndex++; }
      while (matchIndex < found.length && found[matchIndex].end <= start) { matchIndex++; }
      var spanStyle = style ?? const TextStyle();
      if (tokenIndex < tokens.length && tokens[tokenIndex].start <= start) {
        spanStyle = spanStyle.copyWith(color: SyntaxTokens.color(tokens[tokenIndex].kind, scheme));
      }
      if (matchIndex < found.length && found[matchIndex].start <= start) {
        spanStyle = spanStyle.copyWith(
          backgroundColor: scheme.secondaryContainer, color: scheme.onSecondaryContainer,
        );
      }
      spans.add(TextSpan(text: text.substring(start, end), style: spanStyle));
    }
    return TextSpan(style: style, children: spans);
  }
}
