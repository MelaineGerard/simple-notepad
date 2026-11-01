import 'package:flutter/foundation.dart';
import 'package:simple_notepad/model/editor_document.dart';
import 'package:simple_notepad/service/document_store.dart';
import 'package:simple_notepad/service/text_encoding.dart';

enum UnsavedChoice { save, discard, cancel }
typedef ConfirmUnsaved = Future<UnsavedChoice> Function(EditorDocument document);

class DocumentWorkspace extends ChangeNotifier {
  final DocumentStore store;
  final List<EditorDocument> _documents = [];
  int _activeIndex = 0;

  DocumentWorkspace({DocumentStore? store}) : store = store ?? LocalDocumentStore() {
    newDocument();
  }

  List<EditorDocument> get documents => List.unmodifiable(_documents);
  EditorDocument get active => _documents[_activeIndex];
  int get activeIndex => _activeIndex;

  EditorDocument newDocument() {
    final document = EditorDocument();
    _attach(document);
    return document;
  }

  void _attach(EditorDocument document) {
    _documents.add(document);
    document.addListener(notifyListeners);
    _activeIndex = _documents.length - 1;
    notifyListeners();
  }

  void select(int index) {
    if (index < 0 || index >= _documents.length) return;
    _activeIndex = index;
    notifyListeners();
  }

  Future<EditorDocument?> open({TextEncoding? encoding}) async {
    final path = await store.pickOpenPath();
    if (path == null) return null;
    return openPath(path, encoding: encoding);
  }

  Future<EditorDocument> openPath(String path, {TextEncoding? encoding}) async {
    final existing = _documents.indexWhere((document) => document.path == path);
    if (existing >= 0) {
      if (encoding != null && encoding != _documents[existing].encoding) {
        throw StateError('Close this tab before reopening the file with a different encoding.');
      }
      select(existing);
      return active;
    }
    final bytes = await store.read(path);
    final actualEncoding = encoding ?? TextEncoding.detect(bytes);
    final text = actualEncoding.decode(bytes);
    final document = EditorDocument(text: text, path: path, encoding: actualEncoding);
    _attach(document);
    return document;
  }

  Future<bool> save(EditorDocument document, {bool saveAs = false}) async {
    final text = document.textController.text;
    final encoding = document.encoding;
    // Strict conversion happens before opening a picker or modifying a file.
    final bytes = encoding.encode(text);
    var path = document.path;
    if (saveAs || path == null) {
      path = await store.pickSavePath(document.name == 'Untitled' ? 'untitled.txt' : document.name, bytes);
      if (path == null) return false;
    } else {
      await store.write(path, bytes);
    }
    for (final other in _documents) {
      if (other != document && other.path == path) other.markExternalChange();
    }
    document.markSaved(text, encoding, path);
    return true;
  }

  Future<bool> canClose(EditorDocument document, ConfirmUnsaved confirm) async {
    if (!document.isDirty) return true;
    switch (await confirm(document)) {
      case UnsavedChoice.cancel:
        return false;
      case UnsavedChoice.discard:
        return true;
      case UnsavedChoice.save:
        return await save(document) && !document.isDirty;
    }
  }

  Future<bool> close(EditorDocument document, ConfirmUnsaved confirm) async {
    if (!await canClose(document, confirm)) return false;
    final index = _documents.indexOf(document);
    if (index < 0) return false;
    _documents.removeAt(index);
    document.removeListener(notifyListeners);
    if (_documents.isEmpty) {
      newDocument();
    } else {
      if (index < _activeIndex) _activeIndex--;
      _activeIndex = _activeIndex.clamp(0, _documents.length - 1).toInt();
      notifyListeners();
    }
    document.dispose();
    return true;
  }

  Future<bool> canQuit(ConfirmUnsaved confirm) async {
    // Do not remove any tab until every prompt has been accepted.
    for (final document in List<EditorDocument>.of(_documents)) {
      if (!await canClose(document, confirm)) return false;
    }
    return true;
  }

  @override
  void dispose() {
    for (final document in _documents) {
      document.removeListener(notifyListeners);
      document.dispose();
    }
    super.dispose();
  }
}
