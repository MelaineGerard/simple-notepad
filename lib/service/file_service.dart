import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class FileService {
  String currentFilePath = '';

  Future<void> openFile(
      BuildContext context, TextEditingController textController) async {
    final result = await FilePicker.pickFile();

    if (result != null) {
      String? filePath = result.path;
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
    final outputFile = await FilePicker.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'my-awesome-file.txt',
      bytes: Uint8List.fromList(utf8.encode(textController.text)),
      mimeType: 'text/plain',
    );
    if (outputFile != null) {
      currentFilePath = outputFile.toFilePath();

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
    final lines = textController.text.split(RegExp(r'\r?\n'));

    doc.addPage(
      pw.MultiPage(
        build: (pw.Context context) => lines.map((line) => pw.Paragraph(text: line)).toList(),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
