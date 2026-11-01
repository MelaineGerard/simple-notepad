import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String? data);
}

class LocalSessionStore implements SessionStore {
  static const key = 'editorSessionV1';
  @override
  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String? data) async {
    final preferences = await SharedPreferences.getInstance();
    final success = data == null ? await preferences.remove(key) :
        await preferences.setString(key, data);
    if (!success) throw StateError('The previous session could not be saved');
  }
}
