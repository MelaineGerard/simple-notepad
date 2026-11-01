import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // Widget tests have no GTK window. Keep the real Yaru titlebar and editor
    // widgets, while supplying only the platform window-state boundary.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('yaru_window'), (call) async {
      if (call.method == 'state') {
        return <String, dynamic>{
          'title': 'Simple Notepad', 'isActive': true, 'isClosable': true,
          'isMinimizable': true, 'isMaximizable': true, 'isRestorable': false,
        };
      }
      return null;
    });
  });
  await testMain();
}
