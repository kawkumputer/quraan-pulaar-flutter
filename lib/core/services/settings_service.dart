import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _notificationsKey = 'notifications_enabled';

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  final RxDouble _fontSize = 16.0.obs;
  final RxBool _notificationsEnabled = true.obs;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode.value;
  double get fontSize => _fontSize.value;
  bool get notificationsEnabled => _notificationsEnabled.value;

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
    ever(_themeMode, _onThemeModeChanged);
  }

  void _onThemeModeChanged(ThemeMode mode) {
    Get.changeThemeMode(mode);
    _saveThemeMode(mode);
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    final themeModeString = _prefs!.getString(_themeKey) ?? 'system';
    _themeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.system,
    );

    _fontSize.value = _prefs!.getDouble(_fontSizeKey) ?? 16.0;
    _notificationsEnabled.value = _prefs!.getBool(_notificationsKey) ?? true;
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    if (_prefs == null) return;
    await _prefs!.setString(_themeKey, mode.toString().split('.').last);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
  }

  Future<void> setFontSize(double size) async {
    if (_prefs == null) return;
    await _prefs!.setDouble(_fontSizeKey, size);
    _fontSize.value = size;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_notificationsKey, enabled);
    _notificationsEnabled.value = enabled;
  }
}
