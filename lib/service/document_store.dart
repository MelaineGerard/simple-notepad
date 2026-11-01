import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

abstract class DocumentStore {
  Future<String?> pickOpenPath();
  Future<String?> pickSavePath(String name, Uint8List bytes);
  Future<bool> exists(String path);
  Future<Uint8List> read(String path);
  Future<void> write(String path, Uint8List bytes);
}

class LocalDocumentStore implements DocumentStore {
  final Future<void> Function(File file, Uint8List bytes)? writeTemporary;
  LocalDocumentStore({this.writeTemporary});

  @override
  Future<String?> pickOpenPath() async => (await FilePicker.pickFile())?.path;

  @override
  Future<String?> pickSavePath(String name, Uint8List bytes) async {
    // file_picker 13 saveFile writes the destination immediately. Selecting a
    // directory instead lets us confirm overwrite and replace files atomically.
    final directory = await FilePicker.getDirectoryPath(dialogTitle: 'Choose a folder for $name');
    if (directory == null) return null;
    return '$directory${Platform.pathSeparator}$name';
  }

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<Uint8List> read(String path) => File(path).readAsBytes();

  @override
  Future<void> write(String path, Uint8List bytes) async {
    final original = File(path);
    final target = File(await original.exists()
        ? await original.resolveSymbolicLinks() : original.absolute.path);
    final stat = await target.stat();
    final temporary = await target.parent.createTemp('.simple-notepad-');
    try {
      final staged = File('${temporary.path}${Platform.pathSeparator}document');
      if (writeTemporary != null) { await writeTemporary!(staged, bytes); }
      else { await staged.writeAsBytes(bytes, flush: true); }
      if (stat.type == FileSystemEntityType.file && Platform.isLinux) {
        final result = await Process.run('chmod', [
          (stat.mode & 0x1ff).toRadixString(8), staged.path,
        ]);
        if (result.exitCode != 0) throw FileSystemException('Could not preserve file permissions', path);
      }
      await staged.rename(target.path);
    } finally {
      await temporary.delete(recursive: true);
    }
  }
}
