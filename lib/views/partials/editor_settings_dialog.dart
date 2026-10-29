import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/theme.dart';

class EditorSettingsDialog extends StatelessWidget {
  final ApplicationTheme settings;

  const EditorSettingsDialog({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, child) => AlertDialog(
        scrollable: true,
        title: const Text('Settings'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                value: settings.darkMode,
                onChanged: (_) => settings.toggleTheme(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EditorFont>(
                initialValue: settings.editorFont,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Editor font'),
                items: EditorFont.values
                    .map((font) => DropdownMenuItem(
                          value: font,
                          child: Text(font.label),
                        ))
                    .toList(),
                onChanged: (font) {
                  if (font != null) settings.changeEditorFont(font);
                },
              ),
              const SizedBox(height: 16),
              Text('Font size: ${settings.fontSize.round()}'),
              Slider(
                value: settings.fontSize,
                min: 12,
                max: 32,
                divisions: 12,
                label: settings.fontSize.round().toString(),
                onChanged: settings.changeFontSize,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
