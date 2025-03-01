import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../services/bookmark_service.dart';
import '../services/quran_audio_service.dart';
import '../services/settings_service.dart';
import '../services/audio_service.dart';
import '../services/quran_service.dart';
import '../services/cache_service.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../controllers/activation_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Register services as singletons
    Get.put<CacheService>(CacheService(), permanent: true);  // Initialize CacheService first
    Get.put<FirebaseService>(FirebaseService(), permanent: true);
    Get.put<BookmarkService>(BookmarkService(), permanent: true);
    Get.put<QuranAudioService>(QuranAudioService(), permanent: true);
    Get.put<SettingsService>(SettingsService(), permanent: true);
    Get.put<AudioService>(AudioService());
    Get.put<QuranService>(QuranService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<DeviceService>(DeviceService(), permanent: true);
    Get.put<ActivationController>(ActivationController(), permanent: true);
  }
}
