import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/bindings/initial_binding.dart';
import 'core/services/download_service.dart';
import 'core/controllers/audio_controller.dart';
import 'core/services/hadith_service.dart';
import 'core/routes/route_observer.dart';
import 'features/surah/models/surah.dart';
import 'features/surah/models/verse.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SurahAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VerseAdapter());
  }
  
  // Delete existing Hive boxes if they exist
  final appDir = await getApplicationDocumentsDirectory();
  final surahsPath = '${appDir.path}/surahs.hive';
  final metadataPath = '${appDir.path}/metadata.hive';
  
  if (await File(surahsPath).exists()) {
    await File(surahsPath).delete();
  }
  if (await File(metadataPath).exists()) {
    await File(metadataPath).delete();
  }
  
  // Open Hive Boxes
  await Hive.openBox<Surah>('surahs');
  await Hive.openBox<DateTime>('metadata');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: Platform.isIOS
        ? const FirebaseOptions(
            apiKey: 'AIzaSyBs6_6QvWQOTDzrQefCa1UsVU1Rc1jb1r4',
            appId: '1:316874132271:ios:d883672f0e40699ceaafda',
            messagingSenderId: '316874132271',
            projectId: 'quran-pulaar-dmwdqo',
            storageBucket: 'quran-pulaar-dmwdqo.firebasestorage.app',
            iosBundleId: 'mr.quraanpulaar',
          )
        : const FirebaseOptions(
            apiKey: 'AIzaSyBTkrQNZPlu_gj28CGwRd1eOOK-D8qFnxQ',
            appId: '1:316874132271:android:4e2a5fdb7c6c056eeaafda',
            messagingSenderId: '316874132271',
            projectId: 'quran-pulaar-dmwdqo',
            storageBucket: 'quran-pulaar-dmwdqo.firebasestorage.app',
          ),
  );
  
  // Initialize Mobile Ads
  await MobileAds.instance.initialize();
  
  // Initialize background audio service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.kawkumputer.quraan_pulaar.channel.audio',
    androidNotificationChannelName: 'Quraan Pulaar',
    androidNotificationOngoing: false,
    androidShowNotificationBadge: true,
    androidStopForegroundOnPause: true,
    fastForwardInterval: const Duration(seconds: 10),
    rewindInterval: const Duration(seconds: 10),
    preloadArtwork: true,
  );
  
  // Initialize all services
  InitialBinding().dependencies();
  
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Quraan Pulaar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      navigatorObservers: [
        AudioRouteObserver(),
      ],
      defaultTransition: Transition.cupertino,
    );
  }
}
