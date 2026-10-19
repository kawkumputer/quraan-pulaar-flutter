import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../constants/strings.dart';
import '../services/activation_api_service.dart';
import '../services/settings_service.dart';
import '../services/device_service.dart';
import '../services/quran_service.dart';
import '../../features/activation/activation_dialog.dart';

class ActivationController extends GetxController {
  static const Duration _promptInterval = Duration(hours: 24);

  final ActivationApiService _apiService = Get.find<ActivationApiService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  final SettingsService _settingsService = Get.find<SettingsService>();

  final _isVerifying = false.obs;
  final _verificationError = Rxn<String>();

  bool get isVerifying => _isVerifying.value;
  String? get verificationError => _verificationError.value;

  /// Appelé à l'ouverture de l'accueil. La validation serveur d'un appareil activé
  /// est faite par SettingsService ; ici on propose seulement l'activation aux
  /// utilisateurs gratuits, au plus une fois par 24 h et jamais au premier lancement.
  Future<void> checkActivation() async {
    await _settingsService.ready;
    if (_settingsService.isActivated || _settingsService.isFirstLaunch) return;

    final last = _settingsService.lastActivationPrompt;
    if (last != null && DateTime.now().difference(last) < _promptInterval) return;

    await _settingsService.markActivationPrompted();
    await Future.delayed(const Duration(seconds: 2));
    if (!_settingsService.isActivated) {
      await showActivationDialog();
    }
  }

  /// Fermer le dialogue ne change jamais l'état d'activation.
  Future<void> showActivationDialog() async {
    await Get.dialog<bool>(ActivationDialog());
  }

  Future<bool> verifyActivationCode(String code) async {
    try {
      _isVerifying.value = true;
      _verificationError.value = null;

      final deviceInfo = await _deviceService.getDeviceInfo();
      final success = await _apiService.registerDevice(deviceInfo.uniqueId, code);

      if (success) {
        await _settingsService.setActivated(true, code: code);
        await Get.find<QuranService>().loadSurahs(force: true);
        return true;
      }
      _verificationError.value = S.activationFailed;
      return false;
    } catch (e) {
      debugPrint('Error during verification: $e');
      _verificationError.value = S.genericError;
      return false;
    } finally {
      _isVerifying.value = false;
    }
  }

  void setVerificationError(String error) {
    _verificationError.value = error;
  }
}
