import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';

class ActivationController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final DeviceService _deviceService = Get.find<DeviceService>();
  
  final RxBool isVerified = false.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxBool isWebPlatform = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkVerificationStatus();
  }

  Future<void> checkVerificationStatus() async {
    isLoading.value = true;
    error.value = '';
    
    try {
      final prefs = await SharedPreferences.getInstance();
      isVerified.value = prefs.getBool('isVerified') ?? false;
    } catch (e) {
      // If we can't get device info, we're probably on web
      isWebPlatform.value = true;
      error.value = 'This feature is only available in the mobile app';
      print('Error checking verification status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyCode(String code) async {
    if (isWebPlatform.value) {
      error.value = 'This feature is only available in the mobile app';
      return false;
    }

    isLoading.value = true;
    error.value = '';
    
    try {
      final deviceInfo = await _deviceService.getDeviceInfo();
      final success = await _apiService.registerDevice(deviceInfo.uniqueId, code);
      
      if (success) {
        isVerified.value = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isVerified', true);
        return true;
      } else {
        error.value = 'Invalid activation code';
        return false;
      }
    } catch (e) {
      error.value = 'Error verifying code';
      print('Error verifying code: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> generateCode() async {
    try {
      return await _apiService.generateCode();
    } catch (e) {
      error.value = 'Error generating code';
      print('Error generating code: $e');
      return null;
    }
  }
}
