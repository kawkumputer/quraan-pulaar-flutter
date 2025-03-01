import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import '../models/device_info.dart';

class DeviceService extends GetxService {
  final _deviceInfo = DeviceInfoPlugin();

  Future<DeviceInfo> getDeviceInfo() async {
    String deviceId = '';
    String baseOs = '';
    String deviceName = '';
    String deviceModel = '';
    String manufacturer = '';

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      baseOs = androidInfo.version.release;
      deviceName = androidInfo.device;
      deviceModel = androidInfo.model;
      manufacturer = androidInfo.manufacturer;

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
      // Don't return a device for web platform
      rethrow;
    }
  }
}
