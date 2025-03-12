import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'device_service.dart';
import 'quran_service.dart';
import 'tracking_permission_service.dart';

class SettingsService extends GetxService {
  static const String _themeKey = 'theme_mode';
  static const String _fontSizeKey = 'font_size';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _isActivatedKey = 'is_activated';
  static const String _activationCodeKey = 'activation_code';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _lastValidationKey = 'last_validation_time';
  static const Duration _validationInterval = Duration(hours: 24);

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  final RxDouble _fontSize = 16.0.obs;
  final RxBool _notificationsEnabled = true.obs;
  final RxBool _isActivated = false.obs;
  final RxString _activationCode = ''.obs;
  final RxBool _isFirstLaunch = true.obs;
  SharedPreferences? _prefs;

  late final ApiService _apiService;
  late final DeviceService _deviceService;

  ThemeMode get themeMode => _themeMode.value;
  double get fontSize => _fontSize.value;
  bool get notificationsEnabled => _notificationsEnabled.value;
  bool get isActivated => _isActivated.value;
  RxBool get isActivatedRx => _isActivated;
  String get activationCode => _activationCode.value;
  bool get isFirstLaunch => _isFirstLaunch.value;

  bool get needsValidation {
    if (!_isActivated.value) return false;
    
    final lastValidation = DateTime.fromMillisecondsSinceEpoch(
      _prefs?.getInt(_lastValidationKey) ?? 0
    );
    final now = DateTime.now();
    return now.difference(lastValidation) > _validationInterval;
  }

  @override
  void onInit() {
    super.onInit();
    _apiService = Get.find<ApiService>();
    _deviceService = Get.find<DeviceService>();
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
    await _validateDeviceActivation();
    // Notify that initialization is complete
    try {
      if (Get.isRegistered<QuranService>()) {
        Get.find<QuranService>().onSettingsInitialized();
      } else {
        print('QuranService not yet registered');
      }
    } catch (e) {
      print('Error notifying QuranService: $e');
    }
  }

  Future<void> _validateDeviceActivation() async {
    if (!_isActivated.value) return;

    try {
      // Check if we should validate with backend
      if (!needsValidation) {
        print('Skipping validation - last validation was recent');
        return;
      }

      print('Validating device activation on startup...');
      
      // Request tracking permission before accessing device ID
      final hasTrackingPermission = await TrackingPermissionService.requestTrackingPermission();
      if (!hasTrackingPermission) {
        print('Tracking permission denied, skipping validation');
        return;
      }

      final deviceInfo = await _deviceService.getDeviceInfo();
      final validityStatus = await _apiService.checkDeviceValidity(deviceInfo.uniqueId);

      if (validityStatus == false) {
        print('Device activation is explicitly invalid, clearing activation status');
        await clearActivation();
      } else if (validityStatus == true) {
        print('Device activation is valid');
        // Update last validation time
        await _prefs?.setInt(_lastValidationKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        print('Device status uncertain, trusting existing activation');
        // Don't update validation time for uncertain status
      }
    } catch (e) {
      print('Error validating device activation: $e');
      // Don't clear activation on error to allow offline usage
    }
  }

  Future<void> _loadSettings() async {
    if (_prefs == null) return;
    
    final themeModeString = _prefs!.getString(_themeKey) ?? 'light';
    _themeMode.value = ThemeMode.values.firstWhere(
      (mode) => mode.toString() == 'ThemeMode.$themeModeString',
      orElse: () => ThemeMode.light,
    );

    _fontSize.value = _prefs!.getDouble(_fontSizeKey) ?? 16.0;
    _notificationsEnabled.value = _prefs!.getBool(_notificationsKey) ?? true;
    _isActivated.value = _prefs!.getBool(_isActivatedKey) ?? false;
    _activationCode.value = _prefs!.getString(_activationCodeKey) ?? '';
    _isFirstLaunch.value = _prefs!.getBool(_isFirstLaunchKey) ?? true;

    // If this is not the first launch, mark it
    if (_isFirstLaunch.value) {
      await _prefs!.setBool(_isFirstLaunchKey, false);
      _isFirstLaunch.value = false;
    }
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
