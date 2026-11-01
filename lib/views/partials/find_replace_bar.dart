import 'package:flutter/material.dart';
import 'package:simple_notepad/utils/editor_text_controller.dart';

class FindReplaceBar extends StatelessWidget {
  final EditorTextController document;
  final TextEditingController findController;
  final TextEditingController replaceController;
  final FocusNode findFocus;
  final bool showReplace;
  final bool caseSensitive;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<bool> onCaseChanged;
  final VoidCallback onClose;

  const FindReplaceBar({super.key, required this.document,
    required this.findController, required this.replaceController,
    required this.findFocus, required this.showReplace, required this.caseSensitive,
    required this.onQueryChanged, required this.onCaseChanged, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final matches = document.matches;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(width: 220, child: TextField(
              key: const ValueKey('find-query'),
              controller: findController, focusNode: findFocus,
              decoration: const InputDecoration(labelText: 'Find', isDense: true),
              onChanged: onQueryChanged,
              onSubmitted: (_) => document.selectMatch(),
            )),
            Text('${document.selectedMatch + 1} of ${matches.length}',
              semanticsLabel: '${matches.length} matches'),
            IconButton(tooltip: 'Previous match',
              onPressed: matches.isEmpty ? null : () => document.selectMatch(backwards: true),
              icon: const Icon(Icons.keyboard_arrow_up)),
            IconButton(tooltip: 'Next match (Enter)',
              onPressed: matches.isEmpty ? null : () => document.selectMatch(),
              icon: const Icon(Icons.keyboard_arrow_down)),
            FilterChip(label: const Text('Match case'), selected: caseSensitive,
              onSelected: onCaseChanged),
            if (showReplace) ...[
              SizedBox(width: 220, child: TextField(
                key: const ValueKey('replace-text'),
                controller: replaceController,
                decoration: const InputDecoration(labelText: 'Replace with', isDense: true),
              )),
              TextButton(onPressed: matches.isEmpty ? null :
                () => document.replaceOne(replaceController.text), child: const Text('Replace')),
              TextButton(onPressed: matches.isEmpty ? null :
                () => document.replaceAll(replaceController.text), child: const Text('Replace all')),
            ],
            IconButton(tooltip: 'Close search (Esc)', onPressed: onClose, icon: const Icon(Icons.close)),
          ],
        ),
      ),
    );
  }
}
