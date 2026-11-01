import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_notepad/service/document_workspace.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/views/layout.dart';
import 'document_workspace_test.dart' show MemoryStore;

Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    applicationTheme = ApplicationTheme();
    await applicationTheme.ready;
  });
  tearDown(() => applicationTheme.dispose());

  testWidgets('Ctrl+H replaces only the active tab and Escape closes search',
      (tester) async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final first = workspace.active..textController.text = 'cat cat';
    final second = workspace.newDocument()..textController.text = 'cat stays';
    workspace.select(0);
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace)));
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.keyH);
    await tester.enterText(find.byKey(const ValueKey('find-query')), 'cat');
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('replace-text')), 'dog');
    await tester.tap(find.text('Replace all'));
    await tester.pump();
    expect(first.textController.text, 'dog dog');
    expect(second.textController.text, 'cat stays');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('find-query')), findsNothing);
    expect(first.textController.query, '');
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('finding an offscreen match reveals it without taking search focus',
      (tester) async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final document = workspace.active;
    document.textController.value = TextEditingValue(
      text: '${List.filled(300, 'ordinary line').join('\n')}\nneedle',
      selection: const TextSelection.collapsed(offset: 0),
    );
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace)));
    await tester.pumpAndSettle();
    final editor = tester.widget<TextField>(find.byType(TextField));
    expect(editor.scrollController!.offset, 0);
    await key(tester, LogicalKeyboardKey.keyF);
    final query = find.byKey(const ValueKey('find-query'));
    await tester.enterText(query, 'needle');
    await tester.pump();
    final findFocus = tester.widget<TextField>(query).focusNode!;
    document.textController.selectMatch();
    await tester.pumpAndSettle();
    expect(findFocus.hasFocus, isTrue);
    expect(editor.scrollController!.offset, greaterThan(0));
    final editable = tester.state<EditableTextState>(
      find.descendant(of: find.byKey(editor.key!), matching: find.byType(EditableText)),
    );
    final caret = editable.renderEditable.getLocalRectForCaret(
      TextPosition(offset: document.textController.selection.extentOffset),
    );
    expect(caret.top, greaterThanOrEqualTo(0));
    expect(caret.bottom, lessThanOrEqualTo(editable.renderEditable.size.height));
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('Ctrl+F exposes find without replacement fields', (tester) async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace)));
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.keyF);
    expect(find.byKey(const ValueKey('find-query')), findsOneWidget);
    expect(find.byKey(const ValueKey('replace-text')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
