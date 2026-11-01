import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_notepad/service/document_workspace.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/views/layout.dart';
import 'document_workspace_test.dart' show MemoryStore;

Future<void> controlKey(WidgetTester tester, LogicalKeyboardKey key) async {
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

  testWidgets('tab close prompts and Cancel preserves text; Discard closes only one',
      (tester) async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final first = workspace.active;
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'first draft');
    await controlKey(tester, LogicalKeyboardKey.keyT);
    expect(workspace.documents.length, 2);
    await tester.enterText(find.byType(TextField), 'second draft');
    await controlKey(tester, LogicalKeyboardKey.keyW);
    expect(find.text('Save changes to Untitled?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(workspace.documents.length, 2);
    expect(workspace.active.textController.text, 'second draft');
    await controlKey(tester, LogicalKeyboardKey.keyW);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(workspace.documents.length, 1);
    expect(workspace.active, first);
    expect(first.textController.text, 'first draft');
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('mouse tab close uses the filename dialog and respects Save As cancel',
      (tester) async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'draft');
    await tester.tap(find.byTooltip('Close Untitled'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('File name'), findsOneWidget);
    expect(find.text('Choose folder'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(workspace.active.textController.text, 'draft');
    expect(workspace.active.isDirty, isTrue);
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('Ctrl+Q uses unsaved confirmation before invoking window destruction',
      (tester) async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    var quit = false;
    await tester.pumpWidget(MaterialApp(home: AppLayout(
      workspace: workspace, onQuit: () async { quit = true; },
    )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'keep this');
    await controlKey(tester, LogicalKeyboardKey.keyQ);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(quit, isFalse);
    expect(workspace.active.textController.text, 'keep this');
    await controlKey(tester, LogicalKeyboardKey.keyQ);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(quit, isTrue);
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
