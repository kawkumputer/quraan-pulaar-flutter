import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/device_service.dart';
import '../../features/activation/activation_dialog.dart';

class ActivationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  final SettingsService _settingsService = Get.find<SettingsService>();

  final _isVerifying = false.obs;
  final _verificationError = Rxn<String>();

  bool get isVerifying => _isVerifying.value;
  String? get verificationError => _verificationError.value;

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
      // If already activated, verify with backend
      if (_settingsService.isActivated) {
        print('Device is activated, checking validity with backend...');
        
        // Check connectivity first
        final connectivityResult = await Connectivity().checkConnectivity();
        final hasInternet = connectivityResult != ConnectivityResult.none;
        
        if (!hasInternet) {
          print('No internet connection, skipping backend validation');
          return;
        }

        final deviceInfo = await _deviceService.getDeviceInfo();
        final isValid = await _apiService.checkDeviceValidity(deviceInfo.uniqueId);

        if (!isValid) {
          print('Device activation is no longer valid');
          await _settingsService.clearActivation();
          showActivationDialog();
        } else {
          print('Device activation is valid');
        }
      } else {
        print('Device is not activated');
        showActivationDialog();
      }
    } catch (e) {
      print('Error checking activation: $e');
      // Don't show dialog on error to allow offline usage
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

      // First verify the code
      final isValid = await _apiService.checkDeviceValidity(code);
      if (!isValid) {
        _verificationError.value = 'Invalid activation code';
        await _settingsService.clearActivation();
        return false;
      }

      // Get device info for registration
      final deviceInfo = await _deviceService.getDeviceInfo();

      // Register device with activation code
      final success = await _apiService.registerDevice(deviceInfo.uniqueId, code);

      if (success) {
        // Set activation status and save code
        await _settingsService.setActivated(true, code: code);
        return true;
      } else {
        _verificationError.value = 'Failed to register device';
        await _settingsService.clearActivation();
        return false;
      }
    } catch (e) {
      print('Error during verification: $e');
      _verificationError.value = 'Error verifying code: $e';
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
