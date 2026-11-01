import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:simple_notepad/views/pages/home.dart';
import 'package:simple_notepad/views/partials/appbar_actions.dart';
import 'package:simple_notepad/views/partials/editor_status_bar.dart';
import 'package:yaru/widgets.dart';

class AppLayout extends StatefulWidget {
  final MenuService? menuService;

  const AppLayout({super.key, this.menuService});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final textController = TextEditingController();
  final undoController = UndoHistoryController();
  final editorFocus = FocusNode();
  late final MenuService menuService = widget.menuService ?? MenuService();
  bool _focusMode = false;

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
    editorFocus.requestFocus();
  }

  void _command(String command) {
    menuService.handleContextMenu(context, textController, command);
  }

  void _undo() {
    undoController.undo();
    editorFocus.requestFocus();
  }

  void _redo() {
    undoController.redo();
    editorFocus.requestFocus();
  }

  @override
  void dispose() {
    editorFocus.dispose();
    undoController.dispose();
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFocusMode,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true):
            _toggleFocusMode,
        if (_focusMode)
          const SingleActivator(LogicalKeyboardKey.escape): _toggleFocusMode,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true):
            () => _command('Open'),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            () => _command('Save'),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true):
            () => _command('Save as'),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true):
            () => _command('Print'),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            _redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _redo,
      },
      child: Scaffold(
        bottomNavigationBar: _focusMode
            ? null
            : EditorStatusBar(textController: textController),
        appBar: _focusMode
            ? null
            : YaruWindowTitleBar(
                title: const Text('Simple Notepad'),
                actions: [
                  AppBarActions(
                    textController: textController,
                    menuService: menuService,
                    undoController: undoController,
                    onUndo: _undo,
                    onRedo: _redo,
                    onToggleFocusMode: _toggleFocusMode,
                  ),
                ],
              ),
        body: Column(
          children: [
            if (_focusMode)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Exit focus mode (Esc)',
                  onPressed: _toggleFocusMode,
                  icon: const Icon(Icons.fullscreen_exit),
                ),
              ),
            Expanded(
              key: const ValueKey('editor'),
              child: LayoutBuilder(
                builder: (context, constraints) => HomePage(
                  constraints: constraints,
                  textController: textController,
                  undoController: undoController,
                  focusNode: editorFocus,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
