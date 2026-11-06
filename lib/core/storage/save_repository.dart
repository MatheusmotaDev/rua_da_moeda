import 'package:shared_preferences/shared_preferences.dart';

class SaveRepository {
  // Keep the original storage key so the Rua da Moeda rename preserves saves.
  static const key = 'recife_cash.save.v1';
  final SharedPreferences preferences;
  SaveRepository(this.preferences);
  static Future<SaveRepository> open() async =>
      SaveRepository(await SharedPreferences.getInstance());
  String? read() => preferences.getString(key);
  Future<bool> write(String value) => preferences.setString(key, value);
}
