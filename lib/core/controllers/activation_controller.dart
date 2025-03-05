import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/device_service.dart';
import '../services/quran_service.dart';
import '../../features/activation/activation_dialog.dart';

class ActivationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  final SettingsService _settingsService = Get.find<SettingsService>();
  QuranService? _quranService;

  final _isVerifying = false.obs;
  final _verificationError = Rxn<String>();

  bool get isVerifying => _isVerifying.value;
  String? get verificationError => _verificationError.value;

  Future<QuranService> _getQuranService() async {
    if (_quranService != null) return _quranService!;

    try {
      _quranService = Get.find<QuranService>();
      return _quranService!;
    } catch (e) {
      print('QuranService not available yet, retrying in 100ms');
      await Future.delayed(const Duration(milliseconds: 100));
      return _getQuranService();
    }
  }

  @override
  void onReady() {
    super.onReady();
    // Delay the check slightly to ensure all services are ready
    Future.delayed(const Duration(milliseconds: 500), () {
      checkActivation();
    });
  }

  Future<void> checkActivation() async {
    try {
      // If already activated, only verify with backend if 24 hours have passed
      if (_settingsService.isActivated) {
        if (!_settingsService.needsValidation) {
          print('Skipping activation check - last check was within 24 hours');
          return;
        }

        print('Device is activated, checking validity with backend...');

        // Check connectivity first
        final connectivityResult = await Connectivity().checkConnectivity();
        final hasInternet = connectivityResult != ConnectivityResult.none;

        if (!hasInternet) {
          print('No internet connection, trusting existing activation');
          return;
        }

        try {
          final deviceInfo = await _deviceService.getDeviceInfo();
          final validityStatus = await _apiService.checkDeviceValidity(deviceInfo.uniqueId);

          if (validityStatus == true) {
            print('Device activation confirmed valid');
            await _settingsService.setActivated(true, code: _settingsService.activationCode);
          } else if (validityStatus == false) {
            print('Device activation is explicitly invalid');
            await _settingsService.clearActivation();
            showActivationDialog();
          } else {
            // For null (uncertain), trust existing activation
            print('Device status uncertain, trusting existing activation');
            await _settingsService.setActivated(true, code: _settingsService.activationCode);
          }
        } catch (e) {
          print('Error checking validity with backend: $e');
          print('Trusting existing activation due to error');
          return;
        }
      } else {
        print('Device is not activated');
        showActivationDialog();
      }
    } catch (e) {
      print('Error checking activation: $e');
      // Trust existing activation on error
      if (_settingsService.isActivated) {
        print('Trusting existing activation due to error');
        return;
      }
      showActivationDialog();
    }
  }

  Future<void> showActivationDialog() async {
    try {
      final result = await Get.dialog<bool>(
        ActivationDialog(),
        barrierDismissible: false,
      );

      // If user dismisses the dialog or clicks "Later", ensure we're in restricted mode
      if (result != true) {
        await _settingsService.clearActivation();
      }
    } catch (e) {
      print('Error showing activation dialog: $e');
    }
  }

  Future<bool> verifyActivationCode(String code) async {
    try {
      _isVerifying.value = true;
      _verificationError.value = null;

      // Get device info for registration
      final deviceInfo = await _deviceService.getDeviceInfo();

      // Register device with activation code
      final success = await _apiService.registerDevice(deviceInfo.uniqueId, code);

      if (success) {
        // Set activation status and save code
        await _settingsService.setActivated(true, code: code);
        // Reload surahs from Firebase after successful activation
        final quranService = await _getQuranService();
        await quranService.loadSurahs();
        return true;
      } else {
        _verificationError.value = 'Roŋki huuɓnude kaɓirgal ngal, ƴeewto tawo doggol ngol ina moƴƴi';
        await _settingsService.clearActivation();
        return false;
      }
    } catch (e) {
      print('Error during verification: $e');
      _verificationError.value = 'Juumre e ƴeewndagol doggol: $e';
      await _settingsService.clearActivation();
      return false;
    } finally {
      _isVerifying.value = false;
    }
  }

  void setVerificationError(String error) {
    _verificationError.value = error;
  }
}
