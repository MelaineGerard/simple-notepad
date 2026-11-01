import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';
import 'package:simple_notepad/utils/editor_text_controller.dart';

class HomePage extends StatefulWidget {
  final BoxConstraints constraints;
  final TextEditingController textController;
  final UndoHistoryController? undoController;
  final FocusNode? focusNode;
  final bool autofocus;

  const HomePage({
    super.key,
    required this.constraints,
    required this.textController,
    this.undoController,
    this.focusNode,
    this.autofocus = true,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _fieldKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connect(widget.textController);
  }

  void _connect(TextEditingController controller) {
    if (controller is EditorTextController) controller.revealSelection = _reveal;
  }

  void _disconnect(TextEditingController controller) {
    if (controller is EditorTextController && controller.revealSelection == _reveal) {
      controller.revealSelection = null;
    }
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textController != widget.textController) {
      _disconnect(oldWidget.textController);
      _connect(widget.textController);
    }
  }

  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.textController.selection.isValid) return;
      EditableTextState? editable;
      void visit(Element element) {
        if (element is StatefulElement && element.state is EditableTextState) {
          editable = element.state as EditableTextState;
        } else if (editable == null) { element.visitChildElements(visit); }
      }
      _fieldKey.currentContext?.visitChildElements(visit);
      editable?.bringIntoView(TextPosition(offset: widget.textController.selection.extentOffset));
    });
  }

  @override
  void dispose() {
    _disconnect(widget.textController);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: applicationTheme,
      builder: (context, child) => SizedBox(
        width: widget.constraints.maxWidth.isFinite ? widget.constraints.maxWidth : null,
        height: math.max(0.0, widget.constraints.maxHeight),
        child: TextField(
          key: _fieldKey,
          undoController: widget.undoController,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          scrollController: _scrollController,
          expands: true,
          maxLines: null,
          style: TextStyle(
            fontSize: applicationTheme.fontSize,
            fontFamily: applicationTheme.editorFont.family,
            fontFamilyFallback: applicationTheme.editorFont == EditorFont.monospace
                ? const ['DejaVu Sans Mono', 'Liberation Mono', 'Noto Sans Mono'] : null,
            height: 1.2,
          ),
          decoration: InputDecoration(
            hintText: 'Write something... ',
            hintStyle: TextStyle(fontSize: applicationTheme.fontSize),
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          ),
          controller: widget.textController,
        ),
      ),
    );
  }
}
