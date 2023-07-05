import 'package:flutter/material.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:simple_notepad/views/pages/home.dart';
import 'package:yaru_icons/yaru_icons.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final textController = TextEditingController();
  String currentFilePath = '';
  MenuService menuService = MenuService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: YaruWindowTitleBar(
        title: const Text('Simple Notepad'),
        // put the  on the left side of the title bar
        leading: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: PopupMenuButton<String>(
            icon: const Icon(YaruIcons.view_more_horizontal),
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
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return HomePage(
              constraints: constraints, textController: textController);
        },
      ),
    );
  }
}
