import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_notepad/utils/config.dart';

Future<void> pumpEditorReady(WidgetTester tester) async {
  // Startup awaits persisted preferences, whose futures may originate outside
  // the widget test's fake clock. Drain those continuations on the real loop.
  await tester.runAsync(() async {
    await applicationTheme.ready;
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
  expect(find.byType(LinearProgressIndicator), findsNothing,
    reason: 'Session startup must complete before animations are settled');
  await tester.pumpAndSettle();
}
