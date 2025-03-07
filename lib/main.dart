import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/bindings/initial_binding.dart';
import 'core/services/hadith_service.dart';
import 'features/surah/models/surah.dart';
import 'core/controllers/audio_controller.dart';
import 'core/routes/route_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive Adapters
  Hive.registerAdapter(SurahAdapter());
  Hive.registerAdapter(VerseAdapter());
  
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
  
  // Initialize all services
  InitialBinding().dependencies();
  Get.put(HadithService());
  Get.put(AudioController()); 
  
  runApp(const QuranApp());
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Quraan Pulaar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      getPages: AppRoutes.pages,
      initialRoute: AppRoutes.splash,
      navigatorObservers: [
        AudioRouteObserver(), 
      ],
      debugShowCheckedModeBanner: false,
    );
  }
}
