import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/utils/theme.dart';

class HomePage extends StatelessWidget {
  final BoxConstraints constraints;
  final TextEditingController textController;

  const HomePage({
    super.key,
    required this.constraints,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: applicationTheme,
      builder: (context, child) {
        const lineHeight = 1.2;
        final minLines = math.max(
          1,
          ((constraints.maxHeight - 24) /
                  (applicationTheme.fontSize * lineHeight))
              .floor(),
        );
        return ListView(
          children: [
            TextField(
              style: TextStyle(
                fontSize: applicationTheme.fontSize,
                fontFamily: applicationTheme.editorFont.family,
                fontFamilyFallback:
                    applicationTheme.editorFont == EditorFont.monospace
                        ? const [
                            'DejaVu Sans Mono',
                            'Liberation Mono',
                            'Noto Sans Mono',
                          ]
                        : null,
                height: lineHeight,
              ),
              decoration: InputDecoration(
                hintText: 'Write something... ',
                hintStyle: TextStyle(fontSize: applicationTheme.fontSize),
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
              controller: textController,
            ),
          ],
        );
      },
    );
  }
}
