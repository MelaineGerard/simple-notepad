import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_notepad/model/editor_document.dart';
import 'package:simple_notepad/service/document_workspace.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:simple_notepad/service/text_encoding.dart';
import 'package:simple_notepad/views/pages/home.dart';
import 'package:simple_notepad/views/partials/appbar_actions.dart';
import 'package:simple_notepad/views/partials/editor_status_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/widgets.dart';

class AppLayout extends StatefulWidget {
  final MenuService? menuService;
  final DocumentWorkspace? workspace;
  final Future<void> Function()? onQuit;

  const AppLayout({super.key, this.menuService, this.workspace, this.onQuit});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with WindowListener {
  late final DocumentWorkspace workspace = widget.workspace ?? DocumentWorkspace();
  late final MenuService menuService = widget.menuService ?? MenuService();
  bool _focusMode = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    workspace.addListener(_changed);
    windowManager.addListener(this);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  void _focusEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) workspace.active.focusNode.requestFocus();
    });
  }

  void _toggleFocusMode() {
    setState(() => _focusMode = !_focusMode);
    _focusEditor();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_busy) return;
    _busy = true;
    try {
      await operation();
    } catch (error) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Could not complete the action'),
            content: Text('$error\n\nYour open documents have been kept. For a different file encoding, use Open with encoding or the encoding selector.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          ),
        );
      }
    } finally {
      _busy = false;
      _focusEditor();
    }
  }

  Future<UnsavedChoice> _confirm(EditorDocument document) async {
    return await showDialog<UnsavedChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Save changes to ${document.name}?'),
        content: const Text('Unsaved changes will be lost if you discard them.'),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, UnsavedChoice.cancel), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, UnsavedChoice.discard), child: const Text('Discard')),
          FilledButton(onPressed: () => Navigator.pop(context, UnsavedChoice.save), child: const Text('Save')),
        ],
      ),
    ) ?? UnsavedChoice.cancel;
  }

  Future<TextEncoding?> _chooseEncoding() {
    var selected = TextEncoding.utf8;
    return showDialog<TextEncoding>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Open with encoding'),
          content: DropdownButtonFormField<TextEncoding>(
            initialValue: selected,
            decoration: const InputDecoration(labelText: 'File encoding'),
            items: TextEncoding.values.map((encoding) => DropdownMenuItem(value: encoding, child: Text(encoding.label))).toList(),
            onChanged: (encoding) => setDialogState(() => selected = encoding!),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, selected), child: const Text('Open')),
          ],
        ),
      ),
    );
  }

  void _command(String command) {
    if (command == 'Focus mode') { _toggleFocusMode(); return; }
    if (command == 'Undo') { workspace.active.undoController.undo(); _focusEditor(); return; }
    if (command == 'Redo') { workspace.active.undoController.redo(); _focusEditor(); return; }
    // Command injection keeps native file dialogs outside widget tests.
    if (widget.menuService != null && ['Open', 'Save', 'Save as', 'Print'].contains(command)) {
      menuService.handleContextMenu(context, workspace.active.textController, command);
      return;
    }
    _run(() async {
      final document = workspace.active;
      switch (command) {
        case 'New':
          workspace.newDocument();
          break;
        case 'Open':
          await workspace.open();
          break;
        case 'Open with encoding':
          final encoding = await _chooseEncoding();
          if (encoding != null) await workspace.open(encoding: encoding);
          break;
        case 'Save':
          await workspace.save(document);
          break;
        case 'Save as':
          await workspace.save(document, saveAs: true);
          break;
        case 'Close tab':
          await workspace.close(document, _confirm);
          break;
        case 'Quit':
          if (await workspace.canQuit(_confirm)) {
            if (widget.onQuit != null) { await widget.onQuit!(); }
            else { await windowManager.destroy(); }
          }
          break;
        default:
          if (mounted) menuService.handleContextMenu(context, document.textController, command);
      }
    });
  }

  @override
  void onWindowClose() => _command('Quit');

  @override
  void dispose() {
    windowManager.removeListener(this);
    workspace.removeListener(_changed);
    if (widget.workspace == null) workspace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = workspace.active;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFocusMode,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true): _toggleFocusMode,
        if (_focusMode) const SingleActivator(LogicalKeyboardKey.escape): _toggleFocusMode,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () => _command('New'),
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () => _command('New'),
        const SingleActivator(LogicalKeyboardKey.keyW, control: true): () => _command('Close tab'),
        const SingleActivator(LogicalKeyboardKey.keyQ, control: true): () => _command('Quit'),
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): () => _command('Open'),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => _command('Save'),
        const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): () => _command('Save as'),
        const SingleActivator(LogicalKeyboardKey.keyP, control: true): () => _command('Print'),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () => _command('Undo'),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () => _command('Redo'),
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () => _command('Redo'),
      },
      child: Scaffold(
        appBar: _focusMode ? null : YaruWindowTitleBar(
          title: Text('${active.isDirty ? '• ' : ''}${active.name} — Simple Notepad'),
          onClose: (_) => _command('Quit'),
          actions: [
            AppBarActions(undoController: active.undoController, onCommand: _command),
          ],
        ),
        bottomNavigationBar: _focusMode ? null : EditorStatusBar(
          textController: active.textController,
          trailing: Tooltip(
            message: 'Encoding for saving',
            child: DropdownButton<TextEncoding>(
              value: active.encoding,
              isDense: true,
              underline: const SizedBox.shrink(),
              items: TextEncoding.values.map((encoding) => DropdownMenuItem(value: encoding, child: Text(encoding.label))).toList(),
              onChanged: (encoding) { if (encoding != null) active.encoding = encoding; },
            ),
          ),
        ),
        body: Column(children: [
          if (_focusMode)
            Align(alignment: Alignment.centerRight, child: IconButton(
              tooltip: 'Exit focus mode (Esc)', onPressed: _toggleFocusMode,
              icon: const Icon(Icons.fullscreen_exit),
            )),
          if (!_focusMode)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var i = 0; i < workspace.documents.length; i++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: InputChip(
                      key: ValueKey('tab-${workspace.documents[i].id}'),
                      label: Text('${workspace.documents[i].isDirty ? '• ' : ''}${workspace.documents[i].name}'),
                      tooltip: workspace.documents[i].path ?? 'Unsaved document',
                      selected: i == workspace.activeIndex,
                      onPressed: () { workspace.select(i); _focusEditor(); },
                      onDeleted: () {
                        final document = workspace.documents[i];
                        _run(() async { await workspace.close(document, _confirm); });
                      },
                      deleteButtonTooltipMessage: 'Close ${workspace.documents[i].name}',
                    ),
                  ),
                IconButton(tooltip: 'New tab (Ctrl+T)', onPressed: () => _command('New'), icon: const Icon(Icons.add)),
              ]),
            ),
          Expanded(
            key: const ValueKey('editor'),
            child: LayoutBuilder(builder: (context, constraints) => IndexedStack(
              index: workspace.activeIndex,
              children: [
                for (final document in workspace.documents)
                  HomePage(
                    key: ValueKey(document.id),
                    constraints: constraints,
                    textController: document.textController,
                    undoController: document.undoController,
                    focusNode: document.focusNode,
                    autofocus: document == active,
                  ),
              ],
            )),
          ),
        ]),
      ),
    );
  }
}
