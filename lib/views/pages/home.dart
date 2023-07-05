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
    double lineHeight = 1.2;

    int minLines = (viewportHeight / (applicationTheme.fontSize * lineHeight))
        .floor()
        .toInt();

    return ListView(
      children: [
        TextField(
          style: TextStyle(
            fontSize: applicationTheme.fontSize,
            height: lineHeight,
          ),
          decoration: InputDecoration(
            hintText: 'Write something... ',
            hintStyle: TextStyle(
              fontSize: applicationTheme.fontSize,
            ),
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 8,
            ),
          ),
          minLines: minLines,
          maxLines: null,
          controller: widget.textController,
        ),
      ],
    );
  }
}
