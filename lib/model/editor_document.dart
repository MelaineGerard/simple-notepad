import 'package:flutter/material.dart';
import 'package:simple_notepad/service/text_encoding.dart';
import 'package:simple_notepad/utils/editor_text_controller.dart';

class EditorDocument extends ChangeNotifier {
  static int _nextId = 0;
  final int id = _nextId++;
  final EditorTextController textController;
  final UndoHistoryController undoController = UndoHistoryController();
  final FocusNode focusNode = FocusNode();
  String? path;
  TextEncoding _encoding;
  int revision = 0;
  late String _lastText;
  bool _externalChange = false;
  String _savedText;
  TextEncoding _savedEncoding;

  EditorDocument({String text = '', this.path, TextEncoding encoding = TextEncoding.utf8})
      : textController = EditorTextController(text: text, path: path),
        _encoding = encoding, _savedText = text, _savedEncoding = encoding {
    _lastText = text;
    textController.addListener(_textChanged);
  }

  String get name => path == null ? 'Untitled' : path!.split(RegExp(r'[/\\]')).last;
  bool get isDirty => _externalChange || textController.text != _savedText || _encoding != _savedEncoding;
  TextEncoding get encoding => _encoding;
  set encoding(TextEncoding value) {
    if (_encoding == value) return;
    _encoding = value;
    revision++;
    notifyListeners();
  }

  void markSaved(String savedText, TextEncoding savedEncoding, String savedPath) {
    revision++;
    _externalChange = false;
    _savedText = savedText;
    _savedEncoding = savedEncoding;
    path = savedPath;
    textController.filePath = savedPath;
    notifyListeners();
  }

  void markExternalChange() {
    _externalChange = true;
    revision++;
    notifyListeners();
  }

  void _textChanged() {
    if (textController.text != _lastText) {
      _lastText = textController.text;
      revision++;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    textController.removeListener(_textChanged);
    textController.dispose();
    undoController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
