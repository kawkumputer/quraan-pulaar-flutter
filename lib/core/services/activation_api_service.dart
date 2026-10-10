import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/device_service.dart';

/// Activation par code via Supabase (remplace l'ancien backend Spring).
class ActivationApiService extends GetxService {
  SupabaseClient get _client => Supabase.instance.client;

  /// Enregistre l'appareil avec un code d'activation.
  /// Renvoie true si le code est accepté pour cet appareil.
  Future<bool> registerDevice(String deviceId, String activationCode) async {
    try {
      final deviceInfo = await Get.find<DeviceService>().getDeviceInfo();

      final result = await _client.rpc('activate_code', params: {
        'p_code': activationCode.trim(),
        'p_unique_id': deviceId,
        'p_base_os': deviceInfo.baseOs,
        'p_device_name': deviceInfo.deviceName,
        'p_device_model': deviceInfo.deviceModel,
        'p_manufacturer': deviceInfo.manufacturer,
        'p_first_install_time': deviceInfo.firstInstallTime,
      });

      if (result is Map && result['success'] == true) {
        return true;
      }
      debugPrint('Activation refused: ${result is Map ? result['error'] : result}');
      return false;
    } catch (e) {
      debugPrint('Error registering device: $e');
      return false;
    }
  }

  /// Vérifie que [code] est toujours actif et rattaché à cet appareil.
  /// true : appareil activé, false : explicitement non activé,
  /// null : statut inconnu (réseau, serveur, pas de code) -> on garde l'activation locale.
  Future<bool?> checkDeviceValidity(String deviceId, String code) async {
    if (code.trim().isEmpty) return null;
    try {
      final result = await _client.rpc('check_device', params: {
        'p_unique_id': deviceId,
        'p_code': code.trim(),
      });

      if (result == 'valid') return true;
      if (result == 'invalid') return false;
      return null;
    } catch (e) {
      debugPrint('Error checking device validity: $e');
      return null;
    }
  }
}
