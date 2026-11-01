import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:simple_notepad/model/editor_document.dart';
import 'package:simple_notepad/service/document_workspace.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:simple_notepad/service/text_encoding.dart';
import 'package:simple_notepad/service/session_store.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/views/pages/home.dart';
import 'package:simple_notepad/views/partials/appbar_actions.dart';
import 'package:simple_notepad/views/partials/editor_status_bar.dart';
import 'package:simple_notepad/views/partials/find_replace_bar.dart';
import 'package:window_manager/window_manager.dart';
import 'package:yaru/widgets.dart';

class AppLayout extends StatefulWidget {
  final MenuService? menuService;
  final DocumentWorkspace? workspace;
  final Future<void> Function()? onQuit;
  final SessionStore? sessionStore;

  const AppLayout({super.key, this.menuService, this.workspace, this.onQuit, this.sessionStore});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> with WindowListener {
  late final DocumentWorkspace workspace = widget.workspace ?? DocumentWorkspace();
  late final MenuService menuService = widget.menuService ?? MenuService();
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _findFocus = FocusNode();
  bool _showFind = false;
  bool _showReplace = false;
  bool _matchCase = false;
  late final SessionStore sessionStore = widget.sessionStore ?? LocalSessionStore();
  bool get _manageSession => widget.workspace == null || widget.sessionStore != null;
  Timer? _sessionTimer;
  Future<void> _sessionWrites = Future<void>.value();
  bool _restoring = false;
  bool _sessionWarningShown = false;
  bool _recoveryPaused = false;
  bool _focusMode = false;
  bool _busy = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    workspace.addListener(_changed);
    windowManager.addListener(this);
    applicationTheme.addListener(_scheduleSession);
    if (_manageSession) {
      _restoring = true;
      _busy = true;
      _restoreSession();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
    _scheduleSession();
  }

  Future<void> _restoreSession() async {
    String? originalData;
    try {
      await applicationTheme.ready;
      if (!mounted) return;
      if (applicationTheme.restoreSession) {
        final data = await sessionStore.read();
        originalData = data;
        if (!mounted) return;
        if (data != null) {
          final decoded = jsonDecode(data);
          if (decoded is! Map<String, dynamic> || decoded['version'] != 1 || decoded['documents'] is! List) {
            throw const FormatException('Invalid saved session');
          }
          final warnings = await workspace.restoreSession(decoded);
          if (warnings.isNotEmpty) {
            try { await sessionStore.preserve(data); }
            catch (_) { _recoveryPaused = true; }
          }
          if (mounted && warnings.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(warnings.join('\n') + (_recoveryPaused
                  ? '\nRecovery saving is paused because the original session could not be backed up.' : ''))),
              );
            });
          }
        }
      } else {
        await sessionStore.write(null);
      }
    } catch (_) {
      if (originalData != null) {
        try { await sessionStore.preserve(originalData); }
        catch (_) { _recoveryPaused = true; }
      } else { _recoveryPaused = true; }
      if (mounted) WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_recoveryPaused
            ? 'Recovery saving is paused because the previous session could not be backed up. Open documents are unchanged.'
            : 'The previous session could not be restored. Its recovery data was backed up; a new document is ready.'),
        ));
      });
    } finally {
      if (mounted) {
        setState(() { _restoring = false; _busy = false; });
        _scheduleSession();
        _focusEditor();
      }
    }
  }

  Future<void> _queueSession({bool quitting = false}) {
    if (_recoveryPaused && applicationTheme.restoreSession) return Future<void>.value();
    final data = applicationTheme.restoreSession
        ? jsonEncode(workspace.exportSession(quitting: quitting)) : null;
    final write = _sessionWrites.catchError((Object _) {}).then((_) async {
      await sessionStore.write(data);
      if (data == null) _recoveryPaused = false;
    });
    _sessionWrites = write;
    return write;
  }

  void _scheduleSession() {
    if (!_manageSession || !mounted || _restoring || _closing ||
        _recoveryPaused && applicationTheme.restoreSession) return;
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_queueSession().then((_) {
        _sessionWarningShown = false;
      }).catchError((Object _) {
        if (mounted && !_sessionWarningShown) {
          _sessionWarningShown = true;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Session recovery could not be saved. Your open documents are unchanged.'),
          ));
        }
      }));
    });
  }

  Future<void> _flushSessionForQuit() async {
    if (!_manageSession) return;
    _sessionTimer?.cancel();
    await _queueSession(quitting: true);
  }

  void _focusEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_closing && !_restoring) workspace.active.focusNode.requestFocus();
    });
  }

  void _toggleFocusMode() {
    if (_closing || _restoring) return;
    if (!_focusMode) _closeFind();
    setState(() => _focusMode = !_focusMode);
    _focusEditor();
  }

  void _syncSearch() {
    workspace.active.textController.search(
      _showFind ? _findController.text : '', caseSensitive: _matchCase,
    );
  }

  void _openFind(bool replace) {
    if (_closing) return;
    setState(() { _showFind = true; _showReplace = replace; _focusMode = false; });
    _syncSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _findFocus.requestFocus();
    });
  }

  void _closeFind() {
    setState(() => _showFind = false);
    for (final document in workspace.documents) { document.textController.search(''); }
    _focusEditor();
  }

  void _escape() {
    if (_showFind) { _closeFind(); }
    else if (_focusMode) { _toggleFocusMode(); }
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
      if (mounted) _syncSearch();
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

  Future<bool> _saveDocument(EditorDocument document, {bool saveAs = false}) async {
    String? name;
    if (saveAs || document.path == null) {
      var filename = document.path == null ? 'untitled.txt' : document.name;
      name = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Save as'),
            content: TextFormField(
              initialValue: filename, autofocus: true,
              decoration: const InputDecoration(
                labelText: 'File name',
                helperText: 'Choose the destination folder next.',
              ),
              onChanged: (value) => setDialogState(() => filename = value),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: filename.trim().isEmpty ||
                    filename == '.' || filename == '..' ||
                    filename.contains('/') || filename.contains(r'\\') ||
                    filename.contains(String.fromCharCode(0))
                    ? null : () => Navigator.pop(context, filename),
                child: const Text('Choose folder'),
              ),
            ],
          ),
        ),
      );
      if (name == null) return false;
    }
    return workspace.save(document, saveAs: saveAs, fileName: name,
      confirmOverwrite: (path) async => await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace existing file?'),
          content: Text(path),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Replace')),
          ],
        ),
      ) ?? false,
    );
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
    if (_closing) return;
    if (command == 'Find') { _openFind(false); return; }
    if (command == 'Find & Replace') { _openFind(true); return; }
    if (command == 'Settings' || command == 'About') {
      menuService.handleContextMenu(context, workspace.active.textController, command);
      return;
    }
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
          await _saveDocument(document);
          break;
        case 'Save as':
          await _saveDocument(document, saveAs: true);
          break;
        case 'Close tab':
          await workspace.close(document, _confirm, saveDocument: _saveDocument);
          break;
        case 'Quit':
          setState(() => _closing = true);
          document.focusNode.unfocus();
          try {
            if (await workspace.canQuit(_confirm, saveDocument: _saveDocument)) {
              await _flushSessionForQuit();
              if (widget.onQuit != null) { await widget.onQuit!(); }
              else { await windowManager.destroy(); }
            }
          } finally {
            if (mounted) setState(() => _closing = false);
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
    _sessionTimer?.cancel();
    applicationTheme.removeListener(_scheduleSession);
    _findController.dispose();
    _replaceController.dispose();
    _findFocus.dispose();
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
        if (_focusMode || _showFind) const SingleActivator(LogicalKeyboardKey.escape): _escape,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () => _command('Find'),
        const SingleActivator(LogicalKeyboardKey.keyH, control: true): () => _command('Find & Replace'),
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
      child: AbsorbPointer(
        absorbing: _closing || _restoring,
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
          if (_restoring) const LinearProgressIndicator(semanticsLabel: 'Restoring previous session'),
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
                      onPressed: () { workspace.select(i); _syncSearch(); _focusEditor(); },
                      onDeleted: () {
                        final document = workspace.documents[i];
                        _run(() async { await workspace.close(document, _confirm, saveDocument: _saveDocument); });
                      },
                      deleteButtonTooltipMessage: 'Close ${workspace.documents[i].name}',
                    ),
                  ),
                IconButton(tooltip: 'New tab (Ctrl+T)', onPressed: () => _command('New'), icon: const Icon(Icons.add)),
              ]),
            ),
          if (_showFind)
            FindReplaceBar(
              document: active.textController,
              findController: _findController, replaceController: _replaceController,
              findFocus: _findFocus, showReplace: _showReplace, caseSensitive: _matchCase,
              onQueryChanged: (_) => _syncSearch(),
              onCaseChanged: (value) { setState(() => _matchCase = value); _syncSearch(); },
              onClose: _closeFind,
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
                    autofocus: document == active && !_restoring,
                    readOnly: _restoring || _closing,
                  ),
              ],
            )),
          ),
        ]),
        ),
      ),
    );
  }
}
