import 'package:flutter/material.dart';
import 'package:simple_notepad/service/file_service.dart';
import 'package:simple_notepad/utils/config.dart';
import 'package:simple_notepad/views/partials/editor_settings_dialog.dart';

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
      builder: (_) => EditorSettingsDialog(settings: applicationTheme),
    );
  }

  void _handleAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Simple Notepad',
      applicationVersion: '0.1.5',
      applicationLegalese: '© 2026 - Melaine Gérard',
      applicationIcon: const Icon(Icons.note),
    );
  }
}
