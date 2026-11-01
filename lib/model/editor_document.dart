import 'package:flutter/material.dart';
import 'package:simple_notepad/service/text_encoding.dart';

class EditorDocument extends ChangeNotifier {
  static int _nextId = 0;
  final int id = _nextId++;
  final TextEditingController textController;
  final UndoHistoryController undoController = UndoHistoryController();
  final FocusNode focusNode = FocusNode();
  String? path;
  TextEncoding _encoding;
  bool _externalChange = false;
  String _savedText;
  TextEncoding _savedEncoding;

  EditorDocument({String text = '', this.path, TextEncoding encoding = TextEncoding.utf8})
      : textController = TextEditingController(text: text),
        _encoding = encoding, _savedText = text, _savedEncoding = encoding {
    textController.addListener(notifyListeners);
  }

  String get name => path == null ? 'Untitled' : path!.split(RegExp(r'[/\\]')).last;
  bool get isDirty => _externalChange || textController.text != _savedText || _encoding != _savedEncoding;
  TextEncoding get encoding => _encoding;
  set encoding(TextEncoding value) {
    if (_encoding == value) return;
    _encoding = value;
    notifyListeners();
  }

  void markSaved(String savedText, TextEncoding savedEncoding, String savedPath) {
    _externalChange = false;
    _savedText = savedText;
    _savedEncoding = savedEncoding;
    path = savedPath;
    notifyListeners();
  }

  void markExternalChange() {
    _externalChange = true;
    notifyListeners();
  }

  @override
  void dispose() {
    textController.removeListener(notifyListeners);
    textController.dispose();
    undoController.dispose();
    focusNode.dispose();
    super.dispose();
  }
}
