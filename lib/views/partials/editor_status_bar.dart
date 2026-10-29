import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/document_statistics.dart';

class EditorStatusBar extends StatefulWidget {
  final TextEditingController textController;

  const EditorStatusBar({super.key, required this.textController});

  @override
  State<EditorStatusBar> createState() => _EditorStatusBarState();
}

class _EditorStatusBarState extends State<EditorStatusBar> {
  late String _text;
  late DocumentStatistics _statistics;

  @override
  void initState() {
    super.initState();
    _readDocument();
    widget.textController.addListener(_onDocumentChanged);
  }

  @override
  void didUpdateWidget(EditorStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      oldWidget.textController.removeListener(_onDocumentChanged);
      _readDocument();
      widget.textController.addListener(_onDocumentChanged);
    }
  }

  void _readDocument() {
    _text = widget.textController.text;
    _statistics = DocumentStatistics.fromText(_text);
  }

  void _onDocumentChanged() {
    // Caret movement must not recount the entire document.
    if (widget.textController.text != _text) {
      setState(_readDocument);
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onDocumentChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            Text('Lines: ${_statistics.lines}', style: theme.textTheme.bodySmall),
            Text('Words: ${_statistics.words}', style: theme.textTheme.bodySmall),
            Text('Characters: ${_statistics.characters}',
                style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
