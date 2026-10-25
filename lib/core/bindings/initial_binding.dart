import 'package:get/get.dart';
import '../services/quran_service.dart';
import '../services/bookmark_service.dart';
import '../services/download_service.dart';
import '../services/activation_api_service.dart';
import '../services/device_service.dart';
import '../services/quran_sync_service.dart';
import '../services/corrector_service.dart';
import '../services/settings_service.dart';
import '../services/hadith_service.dart';
import '../services/reminder_service.dart';
import '../services/app_config_service.dart';
import '../services/reading_progress_service.dart';
import '../services/search_service.dart';
import '../services/connectivity_service.dart';
import '../controllers/audio_controller.dart';
import '../controllers/activation_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize core services first
    Get.put<ConnectivityService>(ConnectivityService(), permanent: true);
    Get.put<ActivationApiService>(ActivationApiService(), permanent: true);
    Get.put<DeviceService>(DeviceService(), permanent: true);
    Get.put<DownloadService>(DownloadService(), permanent: true);
    Get.put<BookmarkService>(BookmarkService(), permanent: true);
    
    // Register services that depend on core services
    Get.put<SettingsService>(SettingsService(), permanent: true);
    Get.put<QuranSyncService>(QuranSyncService(), permanent: true);
    
    // Initialize QuranService before AudioController
    final quranService = QuranService(
      settingsService: Get.find<SettingsService>(),
      syncService: Get.find<QuranSyncService>(),
    );
    Get.put<QuranService>(quranService, permanent: true);
    
    Get.put<CorrectorService>(CorrectorService(), permanent: true);
    Get.put<ReminderService>(ReminderService(), permanent: true);
    Get.put<AppConfigService>(AppConfigService(), permanent: true);
    Get.put<ReadingProgressService>(ReadingProgressService(), permanent: true);
    Get.put<SearchService>(SearchService(), permanent: true);

    // Initialize HadithService
    Get.put<HadithService>(HadithService(), permanent: true);
    
    // Initialize AudioController after QuranService
    Get.put<AudioController>(AudioController(), permanent: true);
    
    // Initialize other controllers
    Get.put<ActivationController>(ActivationController(), permanent: true);
  }
}
