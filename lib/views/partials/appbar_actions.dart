import 'package:flutter/material.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:yaru_icons/yaru_icons.dart';

class AppBarActions extends StatelessWidget {
  final MenuService menuService;

  final TextEditingController textController;

  const AppBarActions(
      {super.key, required this.textController, required this.menuService});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20.0),
      child: PopupMenuButton<String>(
        icon: const Icon(YaruIcons.menu),
        onSelected: (value) {
          menuService.handleContextMenu(context, textController, value);
        },
        itemBuilder: (BuildContext context) {
          return const [
            PopupMenuItem<String>(
              value: 'Open',
              child: Text('Open'),
            ),
            PopupMenuItem<String>(
              value: 'Save',
              child: Text('Save'),
            ),
            PopupMenuItem<String>(
              value: 'Save as',
              child: Text('Save as'),
            ),
            PopupMenuItem<String>(
              value: 'Print',
              child: Text('Print'),
            ),
            PopupMenuItem<String>(
              value: 'Settings',
              child: Text('Settings'),
            ),
            PopupMenuItem<String>(
              value: 'About',
              child: Text('About'),
            ),
          ];
        },
      ),
    );
  }
}
