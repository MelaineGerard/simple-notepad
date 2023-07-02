import 'package:flutter/material.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notepad'),
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
                ),
                minLines: minLines,
                maxLines: null, // Pour permettre plusieurs lignes de texte
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
        print('Unknown value: $value');
    }
  }
  
  void _handleSettings() {
    // TODO: Open settings
  }
  
  void _handleSave() {
    // TODO: Save content into opened file

  }
  
  void _handleSaveAs() {
    // TODO: Save content into a new file

  }
  
  void _handleOpen() {
    // TODO: Open a file
  }
}
