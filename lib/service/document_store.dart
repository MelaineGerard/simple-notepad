import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

abstract class DocumentStore {
  Future<String?> pickOpenPath();
  Future<String?> pickSavePath(String name, Uint8List bytes);
  Future<Uint8List> read(String path);
  Future<void> write(String path, Uint8List bytes);
}

class LocalDocumentStore implements DocumentStore {
  @override
  Future<String?> pickOpenPath() async => (await FilePicker.pickFile())?.path;

  @override
  Future<String?> pickSavePath(String name, Uint8List bytes) async {
    final uri = await FilePicker.saveFile(fileName: name, bytes: bytes, mimeType: 'text/plain');
    if (uri == null) return null;
    if (uri.scheme != 'file') throw const FileSystemException('A local file is required');
    return uri.toFilePath();
  }

  @override
  Future<Uint8List> read(String path) => File(path).readAsBytes();

  @override
  Future<void> write(String path, Uint8List bytes) async {
    await File(path).writeAsBytes(bytes, flush: true);
  }
}
