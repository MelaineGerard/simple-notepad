import 'package:flutter/material.dart';
import 'package:simple_notepad/service/file_service.dart';
import 'package:simple_notepad/utils/config.dart';

class MenuService {
  final FileService fileService = FileService();

  void handleContextMenu(BuildContext context,
      TextEditingController textController, String value) {
    switch (value) {
      case 'Open':
        fileService.openFile(context, textController);
        break;
      case 'Save':
        fileService.saveFile(context, textController);
        break;
      case 'Save as':
        fileService.saveFileAs(context, textController);
        break;
      case 'Print':
        fileService.printFile(context, textController);
        break;
      case 'Settings':
        _handleSettings(context);
        break;
      case 'About':
        _handleAbout(context);
        break;
      default:
        break;
    }
  }

  void _handleSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: const Text('Settings'),
          content: Column(
            children: [
              Row(
                children: [
                  const Text('Dark mode'),
                  Switch(
                    value: applicationTheme.darkMode,
                    onChanged: (value) async {
                      await applicationTheme.toggleTheme();
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('Font size'),
                  Slider(
                    value: applicationTheme.fontSize,
                    min: 12,
                    max: 32,
                    divisions: 12,
                    label: applicationTheme.fontSize.round().toString(),
                    onChanged: (double value) async {
                      await applicationTheme.changeFontSize(value);
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _handleAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Simple Notepad',
      applicationVersion: '0.0.2',
      applicationLegalese: '© 2023 - Melaine Gérard',
      applicationIcon: const Icon(Icons.note),
    );
  }
}
