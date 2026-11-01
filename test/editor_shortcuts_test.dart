import 'package:flutter/material.dart';
import 'helpers/pump_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/views/layout.dart';
import 'package:simple_notepad/views/partials/editor_status_bar.dart';

class RecordingMenuService extends MenuService {
  final List<String> commands = [];

  @override
  void handleContextMenu(BuildContext context,
      TextEditingController textController, String value) {
    commands.add(value);
  }
}

Future<void> shortcut(WidgetTester tester, LogicalKeyboardKey key,
    {bool control = false, bool shift = false}) async {
  if (control) await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  if (control) await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    applicationTheme = ApplicationTheme();
    await applicationTheme.ready;
  });

  tearDown(() => applicationTheme.dispose());

  testWidgets('focus mode supports both shortcuts, Escape and mouse exit',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLayout()));
    await pumpEditorReady(tester);
    await tester.enterText(find.byType(TextField), 'Keep this document');
    final controller = tester.widget<TextField>(find.byType(TextField)).controller!;
    controller.selection = const TextSelection(baseOffset: 5, extentOffset: 9);
    await shortcut(tester, LogicalKeyboardKey.f11);
    expect(find.byType(EditorStatusBar), findsNothing);
    expect(find.textContaining('— Simple Notepad'), findsNothing);
    expect(controller.text, 'Keep this document');
    expect(controller.selection, const TextSelection(baseOffset: 5, extentOffset: 9));
    await shortcut(tester, LogicalKeyboardKey.escape);
    expect(find.byType(EditorStatusBar), findsOneWidget);
    await shortcut(tester, LogicalKeyboardKey.keyF, control: true, shift: true);
    expect(find.byType(EditorStatusBar), findsNothing);
    await tester.tap(find.byTooltip('Exit focus mode (Esc)'));
    await tester.pump();
    expect(find.byType(EditorStatusBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('file shortcuts dispatch distinct commands without editing text',
      (tester) async {
    final menu = RecordingMenuService();
    await tester.pumpWidget(MaterialApp(home: AppLayout(menuService: menu)));
    await pumpEditorReady(tester);
    await tester.enterText(find.byType(TextField), 'unchanged');
    await shortcut(tester, LogicalKeyboardKey.keyO, control: true);
    await shortcut(tester, LogicalKeyboardKey.keyS, control: true);
    await shortcut(tester, LogicalKeyboardKey.keyS, control: true, shift: true);
    await shortcut(tester, LogicalKeyboardKey.keyP, control: true);
    expect(menu.commands, ['Open', 'Save', 'Save as', 'Print']);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'unchanged');
    await tester.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(seconds: 20)));

  testWidgets('undo redo survives mode and font changes; edits clear redo',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AppLayout()));
    await pumpEditorReady(tester);
    final field = find.byType(TextField);
    await tester.enterText(field, 'one');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.enterText(field, 'one two');
    await tester.pump(const Duration(milliseconds: 600));
    await shortcut(tester, LogicalKeyboardKey.f11);
    await tester.runAsync(
      () => applicationTheme.changeEditorFont(EditorFont.monospace),
    );
    await tester.pump();
    await shortcut(tester, LogicalKeyboardKey.keyZ, control: true);
    expect(tester.widget<TextField>(field).controller!.text, 'one');
    await shortcut(tester, LogicalKeyboardKey.keyY, control: true);
    expect(tester.widget<TextField>(field).controller!.text, 'one two');
    await shortcut(tester, LogicalKeyboardKey.keyZ, control: true);
    await shortcut(tester, LogicalKeyboardKey.keyZ, control: true, shift: true);
    expect(tester.widget<TextField>(field).controller!.text, 'one two');
    await shortcut(tester, LogicalKeyboardKey.keyZ, control: true);
    await tester.enterText(field, 'different');
    await tester.pump(const Duration(milliseconds: 600));
    await shortcut(tester, LogicalKeyboardKey.keyY, control: true);
    expect(tester.widget<TextField>(field).controller!.text, 'different');
    await shortcut(tester, LogicalKeyboardKey.escape);
    await tester.tap(find.byTooltip('Menu'));
    await pumpEditorReady(tester);
    final redo = tester.widget<PopupMenuItem<String>>(
      find.ancestor(of: find.text('Redo'), matching: find.byType(PopupMenuItem<String>)),
    );
    expect(redo.enabled, isFalse);
    await tester.pumpWidget(const SizedBox());
  }, timeout: const Timeout(Duration(seconds: 20)));
}
