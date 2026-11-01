import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad/service/document_store.dart';
import 'package:simple_notepad/service/document_workspace.dart';
import 'package:simple_notepad/service/text_encoding.dart';

class MemoryStore implements DocumentStore {
  final Map<String, Uint8List> files = {};
  String? openPath;
  String? savePath;
  bool failWrites = false;
  Completer<void>? pendingWrite;
  @override
  Future<String?> pickOpenPath() async => openPath;
  @override
  Future<String?> pickSavePath(String name, Uint8List bytes) async {
    if (savePath == null) return null;
    await write(savePath!, bytes);
    return savePath;
  }
  @override
  Future<Uint8List> read(String path) async {
    final bytes = files[path];
    if (bytes == null) throw StateError('Missing file: $path');
    return bytes;
  }
  @override
  Future<void> write(String path, Uint8List bytes) async {
    if (failWrites) throw StateError('Disk full');
    if (pendingWrite != null) await pendingWrite!.future;
    files[path] = Uint8List.fromList(bytes);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('each tab owns text, path, encoding and history', () {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final first = workspace.active;
    first.textController.text = 'first';
    final second = workspace.newDocument();
    second.textController.text = 'second';
    second.encoding = TextEncoding.latin1;
    workspace.select(0);
    expect(workspace.active, first);
    expect(first.textController.text, 'first');
    expect(second.textController.text, 'second');
    expect(first.undoController, isNot(same(second.undoController)));
    workspace.dispose();
  });

  test('cancel and cancelled Save As preserve a dirty tab', () async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final document = workspace.active..textController.text = 'draft';
    expect(await workspace.close(document, (_) async => UnsavedChoice.cancel), isFalse);
    expect(await workspace.close(document, (_) async => UnsavedChoice.save), isFalse);
    expect(workspace.active, document);
    expect(document.isDirty, isTrue);
    workspace.dispose();
  });

  test('successful save precedes closing and flushes the selected encoding', () async {
    final store = MemoryStore()..savePath = '/draft.txt';
    final workspace = DocumentWorkspace(store: store);
    workspace.active.textController.text = 'café';
    workspace.active.encoding = TextEncoding.latin1;
    expect(await workspace.close(workspace.active, (_) async => UnsavedChoice.save), isTrue);
    expect(store.files['/draft.txt'], [99, 97, 102, 233]);
    expect(workspace.active.textController.text, '');
    expect(workspace.active.isDirty, isFalse);
    workspace.dispose();
  });

  test('write failure keeps every document and its unsaved state', () async {
    final store = MemoryStore()..savePath = '/draft.txt'..failWrites = true;
    final workspace = DocumentWorkspace(store: store);
    final document = workspace.active..textController.text = 'draft';
    await expectLater(workspace.close(document, (_) async => UnsavedChoice.save), throwsStateError);
    expect(workspace.documents, [document]);
    expect(document.isDirty, isTrue);
    workspace.dispose();
  });

  test('quit cancellation never removes previously accepted tabs', () async {
    final workspace = DocumentWorkspace(store: MemoryStore());
    final first = workspace.active..textController.text = 'first';
    final second = workspace.newDocument()..textController.text = 'second';
    expect(await workspace.canQuit((doc) async =>
        doc == first ? UnsavedChoice.discard : UnsavedChoice.cancel), isFalse);
    expect(workspace.documents, [first, second]);
    workspace.dispose();
  });

  test('editing during a write does not mark the newer text as saved', () async {
    final store = MemoryStore()..files['/file.txt'] = TextEncoding.utf8.encode('before');
    final workspace = DocumentWorkspace(store: store);
    final document = await workspace.openPath('/file.txt');
    document.textController.text = 'snapshot';
    store.pendingWrite = Completer<void>();
    final saving = workspace.save(document);
    await Future<void>.delayed(Duration.zero);
    document.textController.text = 'newer';
    store.pendingWrite!.complete();
    expect(await saving, isTrue);
    expect(TextEncoding.utf8.decode(store.files['/file.txt']!), 'snapshot');
    expect(document.isDirty, isTrue);
    workspace.dispose();
  });

  test('strict conversion failure leaves disk untouched', () async {
    final store = MemoryStore()..savePath = '/file.txt';
    final workspace = DocumentWorkspace(store: store);
    workspace.active.textController.text = 'café';
    workspace.active.encoding = TextEncoding.ascii;
    await expectLater(workspace.save(workspace.active), throwsA(isA<ArgumentError>()));
    expect(store.files, isEmpty);
    expect(workspace.active.isDirty, isTrue);
    workspace.dispose();
  });

  test('opening a file creates a tab and reopening selects the existing tab', () async {
    final store = MemoryStore()..files['/file.txt'] = TextEncoding.utf16be.encode('hello 🐧');
    final workspace = DocumentWorkspace(store: store);
    final document = await workspace.openPath('/file.txt');
    expect(document.textController.text, 'hello 🐧');
    expect(document.encoding, TextEncoding.utf16be);
    expect(workspace.documents.length, 2);
    expect(await workspace.openPath('/file.txt'), document);
    expect(workspace.documents.length, 2);
    workspace.dispose();
  });

  test('decoding failure does not remove or replace an open draft', () async {
    final store = MemoryStore()..files['/legacy.txt'] = Uint8List.fromList([0xe9]);
    final workspace = DocumentWorkspace(store: store);
    final original = workspace.active..textController.text = 'keep me';
    await expectLater(workspace.openPath('/legacy.txt'), throwsFormatException);
    expect(workspace.documents, [original]);
    final legacy = await workspace.openPath('/legacy.txt', encoding: TextEncoding.latin1);
    expect(legacy.textController.text, 'é');
    workspace.dispose();
  });

  for (final encoding in TextEncoding.values) {
    test('${encoding.label} round trip', () {
      final text = encoding == TextEncoding.ascii ? 'plain text\r\n' :
          encoding == TextEncoding.latin1 ? 'café\r\n' : 'café 🐧\r\n';
      expect(encoding.decode(encoding.encode(text)), text);
    });
  }

  test('UTF-16 rejects truncated units and invalid surrogate pairs', () {
    expect(() => TextEncoding.utf16le.decode([0xff]), throwsFormatException);
    expect(() => TextEncoding.utf16le.decode([0x00, 0xd8, 0x00, 0x00]), throwsFormatException);
  });
}
