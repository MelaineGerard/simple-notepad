import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionStore {
  Future<String?> read();
  Future<void> write(String? data);
  Future<void> preserve(String data);
}

class LocalSessionStore implements SessionStore {
  static const key = 'editorSessionV1';
  static const backupsKey = 'editorSessionBackupsV1';
  @override
  Future<String?> read() async => (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String? data) async {
    final preferences = await SharedPreferences.getInstance();
    final success = data == null ? await preferences.remove(key) :
        await preferences.setString(key, data);
    if (!success) throw StateError('The previous session could not be saved');
    if (data == null && !await preferences.remove(backupsKey)) {
      throw StateError('Recovery backups could not be cleared');
    }
  }
  @override
  Future<void> preserve(String data) async {
    final preferences = await SharedPreferences.getInstance();
    final backups = List<String>.of(preferences.getStringList(backupsKey) ?? []);
    if (backups.contains(data)) return;
    backups.add(data);
    if (!await preferences.setStringList(backupsKey, backups)) {
      throw StateError('The previous recovery data could not be backed up');
    }
  }

}
