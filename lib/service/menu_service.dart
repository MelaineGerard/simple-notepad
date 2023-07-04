
import 'package:flutter/material.dart';
import 'package:simple_notepad/service/file_service.dart';

class MenuService {
  final FileService fileService = FileService();

  void handleContextMenu(BuildContext context, TextEditingController textController, String value) {
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
      default:
        break;
    }
  }
  
  void _handleSettings(BuildContext context) {
    // TODO: Implement settings
    SnackBar snackBar = const SnackBar(
      content: Text('Settings not implemented yet'),
      duration: Duration(seconds: 1),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}