import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_notepad/service/document_workspace.dart';
import 'package:simple_notepad/service/session_store.dart';
import 'package:simple_notepad/service/text_encoding.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/views/layout.dart';
import 'document_workspace_test.dart' show MemoryStore;

class MemorySessionStore implements SessionStore {
  String? data;
  final List<String?> writes = [];
  Completer<void>? firstWrite;
  MemorySessionStore([this.data]);
  @override
  Future<String?> read() async => data;
  @override
  Future<void> write(String? value) async {
    writes.add(value);
    if (writes.length == 1 && firstWrite != null) await firstWrite!.future;
    data = value;
  }
}

class PausedReadStore extends MemoryStore {
  final ready = Completer<void>();
  @override
  Future<Uint8List> read(String path) async {
    await ready.future;
    return super.read(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session restores file tabs, unsaved drafts, selected tab, cursor and encoding', () async {
    final files = MemoryStore()..files['/one.txt'] = TextEncoding.utf16be.encode('on disk');
    final workspace = DocumentWorkspace(store: files);
    final document = await workspace.openPath('/one.txt');
    document.textController.text = 'café draft';
    document.encoding = TextEncoding.latin1;
    document.textController.selection = const TextSelection(baseOffset: 2, extentOffset: 5);
    workspace.newDocument().textController.text = 'untitled draft';
    workspace.select(1);
    final snapshot = workspace.exportSession();
    final restored = DocumentWorkspace(store: files);
    expect(await restored.restoreSession(snapshot), isEmpty);
    expect(restored.documents.length, 3);
    expect(restored.active.path, '/one.txt');
    expect(restored.active.textController.text, 'café draft');
    expect(restored.active.encoding, TextEncoding.latin1);
    expect(restored.active.savedEncoding, TextEncoding.utf16be);
    expect(restored.active.isDirty, isTrue);
    expect(restored.active.textController.selection, const TextSelection(baseOffset: 2, extentOffset: 5));
    expect(restored.documents.last.textController.text, 'untitled draft');
    expect(TextEncoding.utf16be.decode(files.files['/one.txt']!), 'on disk');
    restored.dispose();
    workspace.dispose();
  });

  test('missing files warn, drafts survive as unsaved documents and cursor is clamped', () async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final warnings = await workspace.restoreSession({
      'version': 1, 'active': 1,
      'documents': [
        {'path': '/missing-clean.txt', 'encoding': 'utf8', 'diskEncoding': 'utf8'},
        {'path': '/missing-draft.txt', 'encoding': 'utf8', 'diskEncoding': 'utf8',
          'draft': 'recovered', 'base': 999, 'extent': -1},
      ],
    });
    expect(warnings.length, 2);
    expect(workspace.documents.length, 1);
    expect(workspace.active.path, isNull);
    expect(workspace.active.isDirty, isTrue);
    expect(workspace.active.textController.text, 'recovered');
    expect(workspace.active.textController.selection, const TextSelection(baseOffset: 9, extentOffset: 0));
    workspace.dispose();
  });

  test('restoration never replaces edits started while disk reads were pending', () async {
    final files = PausedReadStore()..files['/one.txt'] = TextEncoding.utf8.encode('disk');
    final workspace = DocumentWorkspace(store: files);
    final original = workspace.active;
    final restoring = workspace.restoreSession({
      'version': 1, 'active': 0,
      'documents': [{'path': '/one.txt', 'encoding': 'utf8', 'diskEncoding': 'utf8'}],
    });
    original.textController.text = 'typed now';
    files.ready.complete();
    expect(await restoring, isNotEmpty);
    expect(workspace.documents, [original]);
    expect(original.textController.text, 'typed now');
    workspace.dispose();
  });

  test('explicit quit discard removes drafts from the final session only', () async {
    final files = MemoryStore()..files['/saved.txt'] = TextEncoding.utf8.encode('original');
    final workspace = DocumentWorkspace(store: files);
    workspace.active.textController.text = 'discard untitled';
    final saved = await workspace.openPath('/saved.txt');
    saved.textController.text = 'discard file edits';
    expect(workspace.exportSession()['documents'][0]['draft'], 'discard untitled');
    expect(await workspace.canQuit((_) async => UnsavedChoice.discard), isTrue);
    final session = workspace.exportSession(quitting: true);
    expect(session['documents'].length, 1);
    expect(session['documents'][0].containsKey('draft'), isFalse);
    final restored = DocumentWorkspace(store: files);
    await restored.restoreSession(session);
    expect(restored.active.textController.text, 'original');
    expect(restored.active.isDirty, isFalse);
    restored.dispose();
    workspace.dispose();
  });

  test('unsupported session formats leave the current document intact', () async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final original = workspace.active;
    expect(await workspace.restoreSession({'version': 99}), isNotEmpty);
    expect(workspace.active, original);
    workspace.dispose();
  });

  test('restore preference persists', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = ApplicationTheme();
    await settings.ready;
    await settings.changeRestoreSession(false);
    final restored = ApplicationTheme();
    await restored.ready;
    expect(restored.restoreSession, isFalse);
    restored.dispose();
    settings.dispose();
  });

  testWidgets('disabled session restore clears old recovery data', (tester) async {
    SharedPreferences.setMockInitialValues({'restoreSession': false});
    await tester.runAsync(() async {
      applicationTheme = ApplicationTheme();
      await applicationTheme.ready;
    });
    final workspace = DocumentWorkspace(store: MemoryStore());
    final sessions = MemorySessionStore('previous data');
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace, sessionStore: sessions)));
    await tester.pumpAndSettle();
    expect(sessions.data, isNull);
    expect(workspace.active.textController.text, '');
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
    applicationTheme.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('quit flush excludes explicitly discarded untitled drafts', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      applicationTheme = ApplicationTheme();
      await applicationTheme.ready;
    });
    final workspace = DocumentWorkspace(store: MemoryStore());
    final sessions = MemorySessionStore();
    var quit = false;
    await tester.pumpWidget(MaterialApp(home: AppLayout(
      workspace: workspace, sessionStore: sessions, onQuit: () async { quit = true; },
    )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'discard me');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(quit, isTrue);
    expect(jsonDecode(sessions.data!)['documents'], isEmpty);
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
    applicationTheme.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('queued recovery writes keep the latest document after a slow write', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      applicationTheme = ApplicationTheme();
      await applicationTheme.ready;
    });
    final workspace = DocumentWorkspace(store: MemoryStore());
    final sessions = MemorySessionStore()..firstWrite = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: AppLayout(workspace: workspace, sessionStore: sessions)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'latest');
    await tester.pump(const Duration(milliseconds: 400));
    sessions.firstWrite!.complete();
    await tester.pumpAndSettle();
    expect(jsonDecode(sessions.data!)['documents'][0]['draft'], 'latest');
    expect(sessions.writes.length, greaterThanOrEqualTo(2));
    await tester.pumpWidget(const SizedBox());
    workspace.dispose();
    applicationTheme.dispose();
  }, timeout: const Timeout(Duration(seconds: 30)));
}
