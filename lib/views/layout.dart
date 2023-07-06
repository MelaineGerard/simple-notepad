import 'package:flutter/material.dart';
import 'package:simple_notepad/service/menu_service.dart';
import 'package:simple_notepad/views/pages/home.dart';
import 'package:simple_notepad/views/partials/appbar_actions.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final textController = TextEditingController();
  MenuService menuService = MenuService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: YaruWindowTitleBar(
        title: const Text('Simple Notepad'),
        actions: [
          AppBarActions(
            textController: textController,
            menuService: menuService,
          ),
        ],
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
