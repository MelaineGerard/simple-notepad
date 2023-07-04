import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key});

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final textController = TextEditingController();
  String currentFilePath = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Notepad'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                _handleContextMenu(value);
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
                    value: 'Settings',
                    child: Text('Settings'),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  focusedBorder: InputBorder.none,
                ),
                minLines: minLines,
                maxLines: null,
                controller: textController,
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleContextMenu(String value) {
    switch (value) {
      case 'Open':
        _handleOpen();
        break;
      case 'Save':
        _handleSave();
        break;
      case 'Save as':
        _handleSaveAs();
        break;
      case 'Settings':
        _handleSettings();
        break;
      default:
        break;
    }
  }

  void _handleSettings() {
    // Open a new page with settings

    const snackBar = SnackBar(
      content: Text('Settings not implemented yet'),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void _handleSave() {
    if (currentFilePath.isNotEmpty) {
      File(currentFilePath).writeAsString(textController.text);

      final snackBar = SnackBar(
        content: Text('Saved $currentFilePath'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      _handleSaveAs();
    }
  }

  Future<void> _handleSaveAs() async {
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'my-awesome-file.txt',
    );
    if (outputFile != null) {
      File(outputFile).writeAsString(textController.text);
      currentFilePath = outputFile;

      final snackBar = SnackBar(
        content: Text('Saved as $currentFilePath'),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  Future<void> _handleOpen() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String? filePath = result.files.single.path;
      if (filePath != null) {
        String fileContent = await File(filePath).readAsString();
        currentFilePath = filePath;

        textController.text = fileContent;

        final snackBar = SnackBar(
          content: Text('Opened $filePath'),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      }
    }
  }
}
