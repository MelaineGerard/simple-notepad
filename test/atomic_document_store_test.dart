import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad/service/document_store.dart';

void main() {
  test('a failed staged write preserves the old file and removes temporary data', () async {
    final directory = await Directory.systemTemp.createTemp('notepad-test-');
    try {
      final original = File('${directory.path}/document.txt');
      await original.writeAsString('original');
      final store = LocalDocumentStore(writeTemporary: (file, bytes) async {
        await file.writeAsBytes(bytes.sublist(0, 2), flush: true);
        throw const FileSystemException('Simulated disk full');
      });
      await expectLater(store.write(original.path, Uint8List.fromList([1,2,3,4])),
          throwsA(isA<FileSystemException>()));
      expect(await original.readAsString(), 'original');
      expect(await directory.list().length, 1);
    } finally { await directory.delete(recursive: true); }
  });

  test('atomic replacement follows symlinks and preserves mode on Linux', () async {
    final directory = await Directory.systemTemp.createTemp('notepad-test-');
    try {
      final original = File('${directory.path}/document.txt');
      await original.writeAsString('old');
      if (Platform.isLinux) await Process.run('chmod', ['640', original.path]);
      final link = Link('${directory.path}/link.txt');
      await link.create(original.path);
      await LocalDocumentStore().write(link.path, Uint8List.fromList([110,101,119]));
      expect(await original.readAsString(), 'new');
      expect(await FileSystemEntity.isLink(link.path), isTrue);
      if (Platform.isLinux) expect((await original.stat()).mode & 0x1ff, 0x1a0);
    } finally { await directory.delete(recursive: true); }
  });
}
