import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../models/code.dart';
import '../models/device_info.dart';
import '../services/device_service.dart';

class ApiService extends GetxService {
  static const List<String> _devUrls = [
    'http://192.168.1.27:8080/api/v1/quran/',  // Your computer's IP - for physical device
    'http://10.0.2.2:8080/api/v1/quran/',      // Android emulator
    'http://localhost:8080/api/v1/quran/',      // Direct localhost
  ];

  late final Dio _dio;
  String? _workingUrl;

  ApiService() {
    _dio = Dio(BaseOptions(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => true,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ));
  }

  Future<bool> _findWorkingUrl() async {
    if (_workingUrl != null) return true;

    for (final url in _devUrls) {
      try {
        print('Trying URL: $url');
        _dio.options.baseUrl = url;
        final response = await _dio.get('');
        print('Connection check response: ${response.statusCode}');

        if (response.statusCode != null) {
          print('Found working URL: $url');
          _workingUrl = url;
          return true;
        }
      } catch (e) {
        print('URL $url failed: $e');
      }
    }
    print('No working URL found, using first URL for development');
    _workingUrl = _devUrls.first;
    return false;
  }

  // Register device with activation code
  Future<bool> registerDevice(String deviceId, String activationCode) async {
    try {
      await _findWorkingUrl();
      print('Registering device ID: $deviceId with code: $activationCode');
      print('Using URL: ${_dio.options.baseUrl}');

      print('Getting device info...');
      final deviceService = Get.find<DeviceService>();
      print('Device service found');

      final deviceInfo = await deviceService.getDeviceInfo();
      print('Device info retrieved:');
      print('  uniqueId: ${deviceInfo.uniqueId}');
      print('  baseOs: ${deviceInfo.baseOs}');
      print('  deviceName: ${deviceInfo.deviceName}');
      print('  deviceModel: ${deviceInfo.deviceModel}');
      print('  manufacturer: ${deviceInfo.manufacturer}');

      final requestData = {
        'code': int.parse(activationCode),
        'deviceInfoModel': {
          'uniqueId': deviceInfo.uniqueId,
          'baseOs': deviceInfo.baseOs,
          'deviceName': deviceInfo.deviceName,
          'deviceModel': deviceInfo.deviceModel,
          'manufacturer': deviceInfo.manufacturer,
          'firstInstallTime': deviceInfo.firstInstallTime,
        }
      };
      print('Sending request with data: $requestData');

      final response = await _dio.post(
        'registration/phoneRegistration',
        data: requestData,
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response data: ${response.data}');

      // Check both status code and response data
      if (response.statusCode == 302 && response.data != null) {
        print('Device registered successfully');
        return true;
      }

      print('Registration failed: Invalid or missing response data');
      return false;

    } on DioException catch (e) {
      print('DioError registering device:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      print('  URL: ${e.requestOptions.uri}');
      if (e.response != null) {
        print('  Response status: ${e.response?.statusCode}');
        print('  Response data: ${e.response?.data}');
      }
      return false;
    } catch (e) {
      print('Unexpected error registering device: $e');
      print('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Check device validity using saved code
  Future<bool?> checkDeviceValidity(String deviceId) async {
    try {
      // If we can't find a working URL, consider it a connection error
      if (!await _findWorkingUrl()) {
        throw DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'No working URL found',
          type: DioExceptionType.connectionError
        );
      }

      print('Checking device validity for ID: $deviceId');

      final response = await _dio.get('ventes/getCodebyPhoneUID/$deviceId');
      print('Device validity check response status: ${response.statusCode}');
      print('Device validity check response data: ${response.data}');

      // Backend returns 302 (FOUND) with code for valid devices
      if (response.statusCode == 302 && response.data != null) {
        print('Device found with valid code');
        return true;
      } else if (response.statusCode == 404) {
        // Explicit "not found" response
        print('Device explicitly not found');
        return false;
      }

      // For any other status code or error, return null to indicate uncertainty
      print('Uncertain device validity status');
      return null;
    } on DioException catch (e) {
      print('DioError checking device validity:');
      print('  Type: ${e.type}');
      print('  Message: ${e.message}');
      // For any Dio error, return null to indicate uncertainty
      return null;
    } catch (e) {
      print('Error checking device validity: $e');
      // For any other error, return null to indicate uncertainty
      return null;
    }
  }
}
