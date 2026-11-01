import 'package:flutter/material.dart';
import 'package:yaru/icons.dart';

class AppBarActions extends StatelessWidget {
  final UndoHistoryController undoController;
  final ValueChanged<String> onCommand;

  const AppBarActions({super.key, required this.undoController, required this.onCommand});

  PopupMenuItem<String> _item(String label, String shortcut, {bool enabled = true}) {
    return PopupMenuItem<String>(
      value: label, enabled: enabled,
      child: Row(children: [
        Expanded(child: Text(label)),
        if (shortcut.isNotEmpty) ...[const SizedBox(width: 24), Text(shortcut)],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: ValueListenableBuilder<UndoHistoryValue>(
        valueListenable: undoController,
        builder: (context, history, child) => PopupMenuButton<String>(
          tooltip: 'Menu', icon: const Icon(YaruIcons.menu),
          onSelected: onCommand,
          itemBuilder: (context) => [
            _item('New', 'Ctrl+N'),
            _item('Open', 'Ctrl+O'),
            _item('Open with encoding', ''),
            _item('Save', 'Ctrl+S'),
            _item('Save as', 'Ctrl+Shift+S'),
            _item('Close tab', 'Ctrl+W'),
            _item('Print', 'Ctrl+P'),
            _item('Find', 'Ctrl+F'),
            _item('Find & Replace', 'Ctrl+H'),
            const PopupMenuDivider(),
            _item('Undo', 'Ctrl+Z', enabled: history.canUndo),
            _item('Redo', 'Ctrl+Y', enabled: history.canRedo),
            const PopupMenuDivider(),
            _item('Focus mode', 'F11'),
            _item('Settings', ''),
            _item('About', ''),
            _item('Quit', 'Ctrl+Q'),
          ],
        ),
      ),
    );
  }
}
