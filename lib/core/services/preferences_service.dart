import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setDarkMode(bool isDark) async {
    await _prefs.setBool('dark_mode', isDark);
  }

  static bool getDarkMode() {
    return _prefs.getBool('dark_mode') ?? false;
  }
}
