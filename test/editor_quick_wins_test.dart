import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/views/pages/home.dart';
import 'package:simple_notepad/views/partials/editor_settings_dialog.dart';
import 'package:simple_notepad/views/partials/editor_status_bar.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('font preference survives a new settings instance', () async {
    final settings = ApplicationTheme();
    await settings.ready;
    await settings.changeEditorFont(EditorFont.monospace);
    final restored = ApplicationTheme();
    await restored.ready;
    expect(restored.editorFont, EditorFont.monospace);
    settings.dispose();
    restored.dispose();
  });

  test('unknown saved font falls back without resetting existing settings', () async {
    SharedPreferences.setMockInitialValues({
      'editorFont': 'removed-font',
      'darkMode': true,
      'fontSize': 20.0,
    });
    final settings = ApplicationTheme();
    await settings.ready;
    expect(settings.editorFont, EditorFont.system);
    expect(settings.darkMode, isTrue);
    expect(settings.fontSize, 20);
    settings.dispose();
  });

  testWidgets('counter follows typing, replacement and clearing', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TextField(controller: controller),
        bottomNavigationBar: EditorStatusBar(textController: controller),
      ),
    ));
    expect(find.text('Words: 0'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'hello world');
    await tester.pump();
    expect(find.text('Words: 2'), findsOneWidget);
    expect(find.text('Characters: 11'), findsOneWidget);
    controller.text = 'opened\nfile\n';
    await tester.pump();
    expect(find.text('Lines: 3'), findsOneWidget);
    controller.clear();
    await tester.pump();
    expect(find.text('Characters: 0'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('settings apply the editor font immediately and persist it', (tester) async {
    applicationTheme = ApplicationTheme();
    await applicationTheme.ready;
    final controller = TextEditingController(text: 'Text stays intact');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomePage(
          constraints: const BoxConstraints(maxHeight: 400),
          textController: controller,
        ),
        floatingActionButton: Builder(builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => EditorSettingsDialog(settings: applicationTheme),
          ),
          child: const Text('Settings'),
        )),
      ),
    ));
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<EditorFont>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monospace').last);
    await tester.pumpAndSettle();
    expect(applicationTheme.editorFont, EditorFont.monospace);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style?.fontFamily, 'monospace');
    expect(controller.text, 'Text stays intact');
    final restored = ApplicationTheme();
    await restored.ready;
    expect(restored.editorFont, EditorFont.monospace);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    restored.dispose();
    applicationTheme.dispose();
  });

  testWidgets('status bar wraps at narrow widths without overflow', (tester) async {
    tester.view.physicalSize = const Size(280, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController(text: 'narrow window');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        bottomNavigationBar: EditorStatusBar(textController: controller),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Words: 2'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
