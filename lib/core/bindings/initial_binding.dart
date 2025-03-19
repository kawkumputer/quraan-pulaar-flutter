import 'package:get/get.dart';
import '../services/quran_service.dart';
import '../services/bookmark_service.dart';
import '../services/download_service.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/ad_service.dart';
import '../services/firebase_service.dart';
import '../services/settings_service.dart';
import '../services/cache_service.dart';
import '../services/hadith_service.dart';
import '../controllers/audio_controller.dart';
import '../controllers/activation_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize core services first
    Get.put<CacheService>(CacheService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<DeviceService>(DeviceService(), permanent: true);
    Get.put<DownloadService>(DownloadService(), permanent: true);
    Get.put<BookmarkService>(BookmarkService(), permanent: true);
    Get.put<AdService>(AdService(), permanent: true);
    
    // Register services that depend on core services
    Get.put<SettingsService>(SettingsService(), permanent: true);
    Get.put<FirebaseService>(FirebaseService(
      cacheService: Get.find<CacheService>(),
      settingsService: Get.find<SettingsService>(),
    ), permanent: true);
    
    // Initialize QuranService before AudioController
    final quranService = QuranService(
      firebaseService: Get.find<FirebaseService>(),
      settingsService: Get.find<SettingsService>(),
      cacheService: Get.find<CacheService>(),
    );
    Get.put<QuranService>(quranService, permanent: true);
    
    // Initialize HadithService
    Get.put<HadithService>(HadithService(), permanent: true);
    
    // Initialize AudioController after QuranService
    Get.put<AudioController>(AudioController(), permanent: true);
    
    // Initialize other controllers
    Get.put<ActivationController>(ActivationController(), permanent: true);
  }
}
