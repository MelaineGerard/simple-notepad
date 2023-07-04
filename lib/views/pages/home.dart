import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final BoxConstraints constraints;
  final TextEditingController textController;

  const HomePage(
      {super.key, required this.constraints, required this.textController});

  @override
  Widget build(BuildContext context) {
    final viewportHeight = constraints.maxHeight;
    const lineHeight = 24.0;
    const fontSize = 16.0;

    final minLines = (viewportHeight / lineHeight).floor();
    
    return ListView(
      children: [
        TextField(
          style: const TextStyle(
            fontSize: fontSize,
            height: lineHeight / fontSize,
          ),
          decoration: const InputDecoration(
            hintText: 'Write something... ',
            contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            focusedBorder: InputBorder.none,
          ),
          minLines: minLines,
          maxLines: null,
          controller: textController,
        ),
      ],
    );
  }
}
