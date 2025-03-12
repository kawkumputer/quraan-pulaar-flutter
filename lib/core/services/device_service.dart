import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import '../models/device_info.dart';
import 'tracking_permission_service.dart';

class DeviceService extends GetxService {
  final _deviceInfo = DeviceInfoPlugin();
  bool _hasRequestedPermission = false;

  Future<DeviceInfo> getDeviceInfo() async {
    try {
      // Request tracking permission on iOS if not already requested
      if (Platform.isIOS && !_hasRequestedPermission) {
        _hasRequestedPermission = true;
        final hasPermission = await TrackingPermissionService.requestTrackingPermission();
        if (!hasPermission) {
          print('Warning: Tracking permission denied, using fallback device ID');
        }
      }

      String deviceId = '';
      String baseOs = '';
      String deviceName = '';
      String deviceModel = '';
      String manufacturer = '';

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
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
