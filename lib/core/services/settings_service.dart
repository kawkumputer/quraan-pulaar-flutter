import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../l10n/app_language.dart';
import 'activation_api_service.dart';
import 'device_service.dart';
import 'tracking_permission_service.dart';

class SettingsService extends GetxService {
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'app_language';
  static const String _fontSizeKey = 'font_size';
  static const String _surahOrderKey = 'surah_order';
  static const String _reminderEnabledKey = 'reminder_enabled';
  static const String _reminderTimeKey = 'reminder_time';
  static const String _lastActivationPromptKey = 'last_activation_prompt';
  static const String _isActivatedKey = 'is_activated';
  static const String _activationCodeKey = 'activation_code';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _lastValidationKey = 'last_validation_time';
  static const Duration _validationInterval = Duration(hours: 24);

  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  /// null tant que l'utilisateur n'a pas choisi (écran de choix au premier lancement).
  final Rxn<AppLanguage> _language = Rxn<AppLanguage>();
  final RxDouble _fontSize = 16.0.obs;
  final Rx<SurahOrder> _surahOrder = SurahOrder.descending.obs;
  final RxBool _reminderEnabled = false.obs;
  final RxInt _reminderMinutes = (7 * 60 + 30).obs;
  final RxBool _isActivated = false.obs;
  final RxString _activationCode = ''.obs;
  bool _isFirstLaunch = true;
  SharedPreferences? _prefs;

  final Completer<void> _ready = Completer<void>();

  late final ActivationApiService _apiService;
  late final DeviceService _deviceService;

  /// Terminé quand les préférences sont chargées (avant toute lecture de l'état d'activation).
  Future<void> get ready => _ready.future;

  ThemeMode get themeMode => _themeMode.value;
  AppLanguage? get language => _language.value;
  Rxn<AppLanguage> get languageRx => _language;
  double get fontSize => _fontSize.value;
  RxDouble get fontSizeRx => _fontSize;
  SurahOrder get surahOrder => _surahOrder.value;
  Rx<SurahOrder> get surahOrderRx => _surahOrder;
  bool get reminderEnabled => _reminderEnabled.value;
  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderMinutes.value ~/ 60, minute: _reminderMinutes.value % 60);
  bool get isActivated => _isActivated.value;
  RxBool get isActivatedRx => _isActivated;
  String get activationCode => _activationCode.value;
  bool get isFirstLaunch => _isFirstLaunch;

  DateTime? get lastActivationPrompt {
    final ms = _prefs?.getInt(_lastActivationPromptKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get needsValidation {
    if (!_isActivated.value) return false;

    final lastValidation = DateTime.fromMillisecondsSinceEpoch(
      _prefs?.getInt(_lastValidationKey) ?? 0
    );
    return DateTime.now().difference(lastValidation) > _validationInterval;
  }

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ActivationApiService>();
    _deviceService = Get.find<DeviceService>();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSettings();
    } finally {
      _ready.complete();
    }
    // Vérification réseau en arrière-plan : ne bloque pas le démarrage.
    validateDeviceActivation();
  }

  /// Vérifie l'activation auprès du serveur (au plus une fois par 24 h).
  Future<void> validateDeviceActivation() async {
    if (!_isActivated.value || !needsValidation) return;

    try {
      // Request tracking permission before accessing device ID
      final hasTrackingPermission = await TrackingPermissionService.requestTrackingPermission();
      if (!hasTrackingPermission) return;

      final deviceInfo = await _deviceService.getDeviceInfo();
      final validityStatus = await _apiService.checkDeviceValidity(deviceInfo.uniqueId, _activationCode.value);

      if (validityStatus == false) {
        await clearActivation();
      } else if (validityStatus == true) {
        await _prefs?.setInt(_lastValidationKey, DateTime.now().millisecondsSinceEpoch);
      }
      // null (incertain) : on garde l'activation sans mettre à jour la date.
    } catch (e) {
      debugPrint('Error validating device activation: $e');
    }
  }

  Future<void> _loadSettings() async {
    final prefs = _prefs!;

    final themeModeString = prefs.getString(_themeKey) ?? 'system';
    _themeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.name == themeModeString,
      orElse: () => ThemeMode.system,
    );

    _language.value = AppLanguage.fromCode(prefs.getString(_languageKey));
    CurrentLanguage.value = _language.value ?? AppLanguage.pulaar;
    _fontSize.value = prefs.getDouble(_fontSizeKey) ?? 16.0;
    _surahOrder.value = SurahOrder.values.firstWhere(
      (o) => o.name == prefs.getString(_surahOrderKey),
      orElse: () => SurahOrder.descending,
    );
    _reminderEnabled.value = prefs.getBool(_reminderEnabledKey) ?? false;
    _reminderMinutes.value = prefs.getInt(_reminderTimeKey) ?? (7 * 60 + 30);
    _isActivated.value = prefs.getBool(_isActivatedKey) ?? false;
    _activationCode.value = prefs.getString(_activationCodeKey) ?? '';

    _isFirstLaunch = prefs.getBool(_isFirstLaunchKey) ?? true;
    if (_isFirstLaunch) {
      await prefs.setBool(_isFirstLaunchKey, false);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);
    await _prefs?.setString(_themeKey, mode.name);
  }

  /// Change la langue de l'interface et reconstruit toute l'app.
  Future<void> setLanguage(AppLanguage language) async {
    _language.value = language;
    CurrentLanguage.value = language;
    await _prefs?.setString(_languageKey, language.code);
    await Get.updateLocale(language.materialLocale);
  }

  Future<void> setFontSize(double size) async {
    _fontSize.value = size;
    await _prefs?.setDouble(_fontSizeKey, size);
  }

  Future<void> setSurahOrder(SurahOrder order) async {
    _surahOrder.value = order;
    await _prefs?.setString(_surahOrderKey, order.name);
  }

  Future<void> setReminder({required bool enabled, TimeOfDay? time}) async {
    _reminderEnabled.value = enabled;
    await _prefs?.setBool(_reminderEnabledKey, enabled);
    if (time != null) {
      _reminderMinutes.value = time.hour * 60 + time.minute;
      await _prefs?.setInt(_reminderTimeKey, _reminderMinutes.value);
    }
  }

  Future<void> markActivationPrompted() async {
    await _prefs?.setInt(_lastActivationPromptKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> setActivated(bool activated, {String? code}) async {
    if (_prefs == null) return;
    await _prefs!.setBool(_isActivatedKey, activated);
    _isActivated.value = activated;

    if (code != null) {
      await _prefs!.setString(_activationCodeKey, code);
      _activationCode.value = code;
      // Set initial validation time when activating
      await _prefs!.setInt(_lastValidationKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> clearActivation() async {
    if (_prefs == null) return;
    await _prefs!.setBool(_isActivatedKey, false);
    await _prefs!.setString(_activationCodeKey, '');
    await _prefs!.remove(_lastValidationKey);
    _isActivated.value = false;
    _activationCode.value = '';
  }
}
