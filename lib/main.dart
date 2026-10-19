import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/config/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/l10n/app_language.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/bindings/initial_binding.dart';
import 'core/routes/route_observer.dart';
import 'core/services/cache_service.dart';
import 'core/services/settings_service.dart';
import 'core/utils/messenger.dart';
import 'core/widgets/mini_player.dart';
import 'features/surah/models/surah.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initHive();

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

  // Initialize Supabase (activation par code)
  await initSupabase();

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
  final settings = Get.find<SettingsService>();
  await settings.ready;

  runApp(QuranApp(
    initialThemeMode: settings.themeMode,
    initialLocale: (settings.language ?? AppLanguage.pulaar).materialLocale,
  ));
}

/// Ouvre les boxes Hive. Le cache n'est vidé que si son format change
/// (kCacheSchemaVersion) ou s'il est illisible.
Future<void> _initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(SurahAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(VerseAdapter());
  }

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt('cache_schema_version') != kCacheSchemaVersion) {
    await Hive.deleteBoxFromDisk(CacheService.surahsBoxName);
    await Hive.deleteBoxFromDisk(CacheService.metadataBoxName);
    await prefs.setInt('cache_schema_version', kCacheSchemaVersion);
  }

  await _openBox<Surah>(CacheService.surahsBoxName);
  await _openBox<DateTime>(CacheService.metadataBoxName);
}

Future<void> _openBox<T>(String name) async {
  try {
    await Hive.openBox<T>(name);
  } catch (e) {
    debugPrint('Hive box $name unreadable, resetting: $e');
    await Hive.deleteBoxFromDisk(name);
    await Hive.openBox<T>(name);
  }
}

class QuranApp extends StatelessWidget {
  final ThemeMode initialThemeMode;
  final Locale initialLocale;

  const QuranApp({super.key, required this.initialThemeMode, required this.initialLocale});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Quraan Pulaar',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: initialThemeMode,
      // Langue de l'interface (S) ; la locale Material gère le sens d'écriture (arabe RTL)
      // et les composants système. Le Pulaar utilise la locale française.
      locale: initialLocale,
      fallbackLocale: const Locale('fr'),
      supportedLocales: const [Locale('fr'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      getPages: AppRoutes.pages,
      navigatorObservers: [AppRouteObserver()],
      scaffoldMessengerKey: rootMessengerKey,
      defaultTransition: Transition.cupertino,
      builder: (context, child) => Column(
        children: [
          Expanded(child: child!),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
