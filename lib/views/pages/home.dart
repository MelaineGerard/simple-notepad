import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/config.dart';

class HomePage extends StatefulWidget {
  final BoxConstraints constraints;
  final TextEditingController textController;

  const HomePage(
      {super.key, required this.constraints, required this.textController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    applicationTheme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var viewportHeight = widget.constraints.maxHeight;
    var lineHeight = max(applicationTheme.fontSize, 24);

    var minLines = (viewportHeight / lineHeight).floor();

    return ListView(
      children: [
        TextField(
          style: TextStyle(
            fontSize: applicationTheme.fontSize,
            height: lineHeight / applicationTheme.fontSize,
          ),
          decoration: InputDecoration(
            hintText: 'Write something... ',
            hintStyle: TextStyle(
              fontSize: applicationTheme.fontSize,
            ),
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.all(2)
          ),
          minLines: minLines,
          maxLines: null,
          controller: widget.textController,
        ),
      ],
    );
  }
}
