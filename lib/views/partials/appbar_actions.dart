import 'package:flutter/material.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:yaru/icons.dart';

class AppBarActions extends StatelessWidget {
  final MenuService menuService;
  final TextEditingController textController;
  final UndoHistoryController undoController;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleFocusMode;

  const AppBarActions({
    super.key,
    required this.textController,
    required this.menuService,
    required this.undoController,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleFocusMode,
  });

  PopupMenuItem<String> _item(String label, String shortcut,
      {bool enabled = true}) {
    return PopupMenuItem<String>(
      value: label,
      enabled: enabled,
      child: Row(
        children: [
          Expanded(child: Text(label)),
          if (shortcut.isNotEmpty) ...[
            const SizedBox(width: 24),
            Text(shortcut),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: ValueListenableBuilder<UndoHistoryValue>(
        valueListenable: undoController,
        builder: (context, history, child) => PopupMenuButton<String>(
          tooltip: 'Menu',
          icon: const Icon(YaruIcons.menu),
          onSelected: (value) {
            switch (value) {
              case 'Undo':
                onUndo();
                break;
              case 'Redo':
                onRedo();
                break;
              case 'Focus mode':
                onToggleFocusMode();
                break;
              default:
                menuService.handleContextMenu(context, textController, value);
            }
          },
          itemBuilder: (context) => [
            _item('Undo', 'Ctrl+Z', enabled: history.canUndo),
            _item('Redo', 'Ctrl+Y', enabled: history.canRedo),
            const PopupMenuDivider(),
            _item('Open', 'Ctrl+O'),
            _item('Save', 'Ctrl+S'),
            _item('Save as', 'Ctrl+Shift+S'),
            _item('Print', 'Ctrl+P'),
            const PopupMenuDivider(),
            _item('Focus mode', 'F11'),
            _item('Settings', ''),
            _item('About', ''),
          ],
        ),
      ),
    );
  }
}
