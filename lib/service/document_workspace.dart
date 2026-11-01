import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show TextSelection;
import 'package:simple_notepad/model/editor_document.dart';
import 'package:simple_notepad/service/document_store.dart';
import 'package:simple_notepad/service/text_encoding.dart';

enum UnsavedChoice { save, discard, cancel }
typedef ConfirmUnsaved = Future<UnsavedChoice> Function(EditorDocument document);

class DocumentWorkspace extends ChangeNotifier {
  final DocumentStore store;
  final List<EditorDocument> _documents = [];
  int _activeIndex = 0;
  bool _disposed = false;
  Set<EditorDocument> _discardOnQuit = {};

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

  Future<bool> save(EditorDocument document, {bool saveAs = false,
      String? fileName, Future<bool> Function(String path)? confirmOverwrite}) async {
    final text = document.textController.text;
    final encoding = document.encoding;
    // Strict conversion happens before opening a picker or modifying a file.
    final bytes = encoding.encode(text);
    var path = document.path;
    if (saveAs || path == null) {
      path = await store.pickSavePath(fileName ?? (document.name == 'Untitled' ? 'untitled.txt' : document.name), bytes);
      if (path == null) return false;
      if (await store.exists(path) && (confirmOverwrite == null || !await confirmOverwrite(path))) return false;
    }
    await store.write(path, bytes);
    for (final other in _documents) {
      if (other != document && other.path == path) other.markExternalChange();
    }
    document.markSaved(text, encoding, path);
    return true;
  }

  Future<bool> canClose(EditorDocument document, ConfirmUnsaved confirm,
      {Future<bool> Function(EditorDocument)? saveDocument}) async {
    if (!document.isDirty) return true;
    final revision = document.revision;
    switch (await confirm(document)) {
      case UnsavedChoice.cancel:
        return false;
      case UnsavedChoice.discard:
        return document.revision == revision;
      case UnsavedChoice.save:
        return await (saveDocument?.call(document) ?? save(document)) && !document.isDirty;
    }
  }

  Future<bool> close(EditorDocument document, ConfirmUnsaved confirm,
      {Future<bool> Function(EditorDocument)? saveDocument}) async {
    if (!await canClose(document, confirm, saveDocument: saveDocument)) return false;
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

  Future<bool> canQuit(ConfirmUnsaved confirm,
      {Future<bool> Function(EditorDocument)? saveDocument}) async {
    _discardOnQuit = {};
    final discarded = <EditorDocument>{};
    final documents = List<EditorDocument>.of(_documents);
    final approved = <EditorDocument, int>{};
    for (final document in documents) {
      if (!await canClose(document, (document) async {
        final choice = await confirm(document);
        if (choice == UnsavedChoice.discard) discarded.add(document);
        return choice;
      }, saveDocument: saveDocument)) return false;
      approved[document] = document.revision;
    }
    // Earlier tabs may have changed while a later file was being saved.
    final approvedAll = listEquals(documents, _documents) &&
        approved.entries.every((entry) => entry.key.revision == entry.value);
    if (approvedAll) _discardOnQuit = discarded;
    return approvedAll;
  }

  Map<String, dynamic> exportSession({bool quitting = false}) {
    final included = _documents.where((document) =>
        !(quitting && _discardOnQuit.contains(document) && document.path == null)).toList();
    return {
      'version': 1,
      'active': included.indexOf(active).clamp(0, included.length).toInt(),
      'documents': [
        for (final document in included)
          {
            'path': document.path,
            'encoding': quitting && _discardOnQuit.contains(document)
                ? document.savedEncoding.name : document.encoding.name,
            'diskEncoding': document.savedEncoding.name,
            if (document.isDirty && !(quitting && _discardOnQuit.contains(document)))
              'draft': document.textController.text,
            'base': document.textController.selection.baseOffset,
            'extent': document.textController.selection.extentOffset,
          },
      ],
    };
  }

  Future<List<String>> restoreSession(Map<String, dynamic> snapshot) async {
    final warnings = <String>[];
    if (_disposed) return warnings;
    if (_documents.length != 1 || active.path != null || active.isDirty ||
        active.textController.text.isNotEmpty) {
      return ['The saved session was not restored because editing has already started.'];
    }
    if (snapshot['version'] != 1 || snapshot['documents'] is! List) {
      return ['The saved session has an unsupported format.'];
    }
    final initial = List<EditorDocument>.of(_documents);
    final initialRevision = active.revision;
    final restored = <EditorDocument>[];
    final originalIndices = <int>[];
    final records = snapshot['documents'] as List;
    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      if (record is! Map || record['path'] != null && record['path'] is! String) {
        warnings.add('An invalid saved tab was skipped.');
        continue;
      }
      TextEncoding parseEncoding(dynamic name) => TextEncoding.values.firstWhere(
        (encoding) => encoding.name == name,
        orElse: () => TextEncoding.utf8,
      );
      final path = record['path'] as String?;
      final encoding = parseEncoding(record['encoding']);
      final diskEncoding = parseEncoding(record['diskEncoding']);
      final draft = record['draft'] is String ? record['draft'] as String : null;
      EditorDocument document;
      var missing = false;
      if (path != null) {
        try {
          final bytes = await store.read(path);
          document = EditorDocument(
            text: diskEncoding.decode(bytes), path: path, encoding: diskEncoding,
          );
        } catch (_) {
          warnings.add('Could not reopen $path.');
          if (draft == null) continue;
          document = EditorDocument();
          missing = true;
        }
      } else { document = EditorDocument(); }
      document.encoding = encoding;
      if (draft != null) document.textController.text = draft;
      if (missing) document.markExternalChange();
      final length = document.textController.text.length;
      final base = record['base'] is int ? record['base'] as int : 0;
      final extent = record['extent'] is int ? record['extent'] as int : 0;
      document.textController.selection = TextSelection(
        baseOffset: base.clamp(0, length).toInt(),
        extentOffset: extent.clamp(0, length).toInt(),
      );
      restored.add(document);
      originalIndices.add(index);
    }
    if (_disposed || !listEquals(initial, _documents) || active.revision != initialRevision) {
      for (final document in restored) { document.dispose(); }
      return ['The saved session was not restored because editing has already started.'];
    }
    if (restored.isEmpty) return warnings;
    for (final document in _documents) {
      document.removeListener(notifyListeners);
      document.dispose();
    }
    _documents.clear();
    for (final document in restored) { _attach(document); }
    final savedActive = snapshot['active'];
    final activeIndex = originalIndices.indexOf(savedActive is int ? savedActive : 0);
    _activeIndex = activeIndex < 0 ? 0 : activeIndex;
    notifyListeners();
    return warnings;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final document in _documents) {
      document.removeListener(notifyListeners);
      document.dispose();
    }
    _documents.clear();
    super.dispose();
  }
}
