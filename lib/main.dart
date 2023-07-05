import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/views/layout.dart';
import 'package:yaru/yaru.dart';

void main() {
  runApp(const SimpleNotepadApplication());
}

class SimpleNotepadApplication extends StatefulWidget {
  const SimpleNotepadApplication({super.key});

  @override
  State<SimpleNotepadApplication> createState() => _SimpleNotepadApplicationState();
}

class _SimpleNotepadApplicationState extends State<SimpleNotepadApplication> {

  @override
  void initState() {
    super.initState();
    applicationTheme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return YaruTheme(builder: (context, yaru, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: yaru.theme,
        darkTheme: yaru.darkTheme,
        themeMode: applicationTheme.currentTheme(),
        home: const AppLayout(),
      );
    });
  }
}
