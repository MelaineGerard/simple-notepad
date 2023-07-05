import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FileService {
  String currentFilePath = '';

  Future<void> openFile(
      BuildContext context, TextEditingController textController) async {
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

  Future<void> saveFile(
      BuildContext context, TextEditingController textController) async {
    if (currentFilePath.isNotEmpty) {
      File(currentFilePath).writeAsString(textController.text);

      final snackBar = SnackBar(
        content: Text('Saved $currentFilePath'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      await saveFileAs(context, textController);
    }
  }

  Future<void> saveFileAs(
      BuildContext context, TextEditingController textController) async {
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

  Future<void> printFile(
      BuildContext context, TextEditingController textController) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Text(textController.text),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
