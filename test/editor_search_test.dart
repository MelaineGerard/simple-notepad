import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/utils/editor_text_controller.dart';
import 'package:simple_notepad/utils/syntax_tokens.dart';

void main() {
  test('literal queries, case matching and navigation wrap in both directions', () {
    final controller = EditorTextController(text: 'cat Cat cat .+');
    controller.search('cat');
    expect(controller.matches.length, 3);
    controller.selectMatch();
    expect(controller.selection, const TextSelection(baseOffset: 0, extentOffset: 3));
    controller.selectMatch(backwards: true);
    expect(controller.selection, const TextSelection(baseOffset: 8, extentOffset: 11));
    controller.selectMatch();
    expect(controller.selection.start, 0);
    controller.search('cat', caseSensitive: true);
    expect(controller.matches.length, 2);
    controller.search('.+');
    expect(controller.matches.single.start, 12);
    controller.dispose();
  });

  test('replacement is literal and scoped to the current document', () {
    final controller = EditorTextController(text: 'cat Cat cat');
    controller.search('cat');
    expect(controller.replaceOne('dog'), isTrue);
    expect(controller.text, 'dog Cat cat');
    expect(controller.replaceAll(r'$'), 2);
    expect(controller.text, r'dog $ $');
    controller.search('');
    expect(controller.replaceAll('ignored'), 0);
    expect(controller.text, r'dog $ $');
    controller.dispose();
  });

  test('replace all uses the original ranges even if replacement contains query', () {
    final controller = EditorTextController(text: 'aaa 🐧');
    controller.search('a');
    expect(controller.replaceAll('aa'), 3);
    expect(controller.text, 'aaaaaa 🐧');
    controller.search('🐧');
    expect(controller.replaceOne('é'), isTrue);
    expect(controller.text, 'aaaaaa é');
    controller.dispose();
  });

  test('extension detection falls back to plain text and handles case', () {
    expect(SyntaxTokens.languageForPath('/tmp/FILE.JSON'), 'json');
    expect(SyntaxTokens.languageForPath('/tmp/script.py'), 'python');
    expect(SyntaxTokens.languageForPath('/tmp/config.yml'), 'yaml');
    expect(SyntaxTokens.languageForPath('/tmp/readme.md'), 'markdown');
    expect(SyntaxTokens.languageForPath('/tmp/file.unknown'), isNull);
    expect(SyntaxTokens.parse('no special syntax', null), isEmpty);
  });

  test('strings shield comment markers and token ranges never overlap', () {
    const source = 'const value = "// literal"; // real comment\nreturn 42;';
    final tokens = SyntaxTokens.parse(source, 'javascript');
    expect(tokens.where((token) => token.kind == 0).length, 1);
    expect(tokens.where((token) => token.kind == 1).length, 1);
    expect(tokens.any((token) => token.kind == 3), isTrue);
    for (var i = 1; i < tokens.length; i++) {
      expect(tokens[i].start, greaterThanOrEqualTo(tokens[i - 1].end));
    }
  });

  test('unterminated block comments consume the tail once and large files fall back', () {
    final source = '/* ' * 20000;
    final tokens = SyntaxTokens.parse(source, 'javascript');
    expect(tokens.length, 1);
    expect(tokens.single.start, 0);
    expect(tokens.single.end, source.length);
    expect(SyntaxTokens.parse('x' * (SyntaxTokens.maxHighlightCharacters + 1), 'python'), isEmpty);
  });

  test('syntax preference persists across application settings instances', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = ApplicationTheme();
    await settings.ready;
    await settings.changeSyntaxHighlighting(false);
    final restored = ApplicationTheme();
    await restored.ready;
    expect(restored.syntaxHighlighting, isFalse);
    restored.dispose();
    settings.dispose();
  });

  testWidgets('highlighting and IME composition preserve exact text and selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      applicationTheme = ApplicationTheme();
      await applicationTheme.ready;
    });
    final controller = EditorTextController(text: 'const text = "café 🐧";', path: '/file.js');
    controller.search('café');
    controller.selection = const TextSelection.collapsed(offset: 3);
    late TextSpan span;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      span = controller.buildTextSpan(context: context,
        style: const TextStyle(fontSize: 14), withComposing: true);
      return Text.rich(span);
    })));
    expect(span.toPlainText(), controller.text);
    expect(controller.selection.extentOffset, 3);
    controller.value = controller.value.copyWith(composing: const TextRange(start: 0, end: 5));
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      span = controller.buildTextSpan(context: context,
        style: const TextStyle(fontSize: 14), withComposing: true);
      return Text.rich(span);
    })));
    expect(span.toPlainText(), controller.text);
    expect(controller.value.composing, const TextRange(start: 0, end: 5));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    applicationTheme.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
