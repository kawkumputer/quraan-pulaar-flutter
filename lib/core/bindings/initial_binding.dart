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
    // Register core services first
    Get.put<CacheService>(CacheService(), permanent: true);
    Get.put<ApiService>(ApiService(), permanent: true);
    Get.put<DeviceService>(DeviceService(), permanent: true);
    
    // Register services that depend on core services
    Get.put<SettingsService>(SettingsService(), permanent: true);
    Get.put<FirebaseService>(FirebaseService(), permanent: true);
    Get.put<BookmarkService>(BookmarkService(), permanent: true);
    Get.put<QuranAudioService>(QuranAudioService(), permanent: true);
    Get.put<AudioService>(AudioService());

    // Register QuranService with its dependencies
    final quranService = QuranService(
      firebaseService: Get.find<FirebaseService>(),
      settingsService: Get.find<SettingsService>(),
    );
    Get.put<QuranService>(quranService, permanent: true);
    
    // Register controllers last since they depend on services
    Get.put<ActivationController>(ActivationController(), permanent: true);
  }
}
