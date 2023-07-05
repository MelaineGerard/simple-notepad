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
    // generate a dialog with a switch to toggle the dark mode
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Row(
            children: [
              const Text('Dark mode'),
              Switch(
                value: applicationTheme.darkMode,
                onChanged: (value) {
                  applicationTheme.toggleTheme();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Simple Notepad',
      applicationVersion: '0.0.1',
      applicationLegalese: '© 2023 - Melaine Gérard',
      applicationIcon: const Icon(Icons.note),
    );
  }
}
