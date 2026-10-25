import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/supabase_config.dart';
import 'core/l10n/app_language.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/bindings/initial_binding.dart';
import 'core/routes/route_observer.dart';
import 'core/services/settings_service.dart';
import 'core/utils/messenger.dart';
import 'core/widgets/mini_player.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
