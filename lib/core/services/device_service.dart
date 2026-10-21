import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/device_info.dart';

class DeviceService extends GetxService {
  final _deviceInfo = DeviceInfoPlugin();
  // Implémenté dans android/app/src/main/kotlin/mr/quran_pulaar/MainActivity.kt
  static const _deviceChannel = MethodChannel('mr.quran_pulaar/device');

  Future<DeviceInfo> getDeviceInfo() async {
    try {
      // iOS : identifierForVendor ne nécessite aucune autorisation (pas d'ATT :
      // l'identifiant sert seulement à l'activation, jamais au suivi publicitaire).
      String deviceId = '';
      String baseOs = '';
      String deviceName = '';
      String deviceModel = '';
      String manufacturer = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // ANDROID_ID : propre à l'appareil, stable aux réinstallations et mises à jour.
        // (androidInfo.id est Build.ID, la version du firmware, partagée par
        // de nombreux téléphones : ne pas l'utiliser comme identifiant.)
        final androidId = await _deviceChannel.invokeMethod<String>('getAndroidId');
        if (androidId == null || androidId.isEmpty) {
          throw StateError('ANDROID_ID unavailable');
        }
        deviceId = androidId;
        baseOs = 'Android ${androidInfo.version.release}';
        deviceName = androidInfo.device;
        deviceModel = androidInfo.model;
        manufacturer = androidInfo.manufacturer;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use a fallback ID if tracking permission is denied
        deviceId = iosInfo.identifierForVendor ?? 'temporary_${DateTime.now().millisecondsSinceEpoch}';
        baseOs = 'iOS ${iosInfo.systemVersion}';
        deviceName = iosInfo.name ?? 'iPhone';
        deviceModel = iosInfo.model ?? 'iOS Device';
        manufacturer = 'Apple';
      } else {
        throw UnsupportedError('Platform not supported');
      }

      return DeviceInfo(
        uniqueId: deviceId,
        baseOs: baseOs,
        deviceName: deviceName,
        deviceModel: deviceModel,
        manufacturer: manufacturer,
        firstInstallTime: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error getting device info: $e');
      rethrow;
    }
  }
}
