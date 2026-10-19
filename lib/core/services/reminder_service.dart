import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../routes/app_routes.dart';
import '../utils/daily_verse.dart';
import 'quran_service.dart';
import 'settings_service.dart';

/// Rappel quotidien local avec le verset du jour.
/// Une notification a un contenu fixe : on programme donc les 14 prochains jours,
/// chacun avec son verset, et on reprogramme à chaque démarrage / retour dans l'app.
class ReminderService extends GetxService {
  static const int _firstId = 1000;
  static const int _days = 14;

  final _plugin = FlutterLocalNotificationsPlugin();
  late final SettingsService _settings;
  late final QuranService _quranService;
  Future<void>? _initFuture;
  AppLifecycleListener? _lifecycleListener;

  @override
  void onInit() {
    super.onInit();
    _settings = Get.find<SettingsService>();
    _quranService = Get.find<QuranService>();

    // Les sourates accessibles changent (chargement, activation) : nouveaux versets.
    debounce(_quranService.surahsRx, (_) => reschedule(), time: const Duration(seconds: 2));
    _lifecycleListener = AppLifecycleListener(onResume: reschedule);
  }

  @override
  void onClose() {
    _lifecycleListener?.dispose();
    super.onClose();
  }

  Future<void> _ensureInitialized() => _initFuture ??= _init();

  Future<void> _init() async {
    tz.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Unknown local timezone, using UTC: $e');
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) => _openPayload(response.payload),
    );

    // App lancée en touchant une notification.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _pendingPayload = launch!.notificationResponse?.payload;
    }
  }

  String? _pendingPayload;

  /// À appeler une fois l'accueil affiché : ouvre la sourate de la notification
  /// qui a lancé l'app, le cas échéant.
  Future<void> handleLaunchNotification() async {
    await _ensureInitialized();
    final payload = _pendingPayload;
    _pendingPayload = null;
    _openPayload(payload);
  }

  Future<void> _openPayload(String? payload) async {
    // payload : « surah:<numéro>:<index du verset> »
    final parts = payload?.split(':') ?? const [];
    final number = int.tryParse(parts.elementAtOrNull(1) ?? '');
    if (number == null) return;
    await _quranService.loadSurahs();
    final surah = _quranService.byNumber(number);
    if (surah != null) {
      AppRoutes.openSurah(surah, verseIndex: int.tryParse(parts.elementAtOrNull(2) ?? ''));
    }
  }

  /// Demande l'autorisation d'afficher des notifications. Renvoie false si refusée.
  Future<bool> requestPermission() async {
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Active / désactive le rappel. Renvoie false si l'autorisation est refusée.
  Future<bool> setEnabled(bool enabled, {TimeOfDay? time}) async {
    if (enabled && !await requestPermission()) {
      await _settings.setReminder(enabled: false);
      return false;
    }
    await _settings.setReminder(enabled: enabled, time: time);
    await reschedule();
    return true;
  }

  Future<void> reschedule() async {
    try {
      await _ensureInitialized();
      for (var i = 0; i < _days; i++) {
        await _plugin.cancel(id: _firstId + i);
      }
      if (!_settings.reminderEnabled) return;

      final surahs = _quranService.accessibleSurahs;
      if (surahs.isEmpty) return;

      final time = _settings.reminderTime;
      final now = tz.TZDateTime.now(tz.local);

      for (var i = 0; i < _days; i++) {
        final day = tz.TZDateTime(tz.local, now.year, now.month, now.day + i, time.hour, time.minute);
        if (!day.isAfter(now)) continue;
        final daily = DailyVerse.forDate(day, surahs);
        if (daily == null) continue;

        final details = NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_verse',
            'Maande ñalnde',
            channelDescription: 'Ciftinal maande hannde',
            importance: Importance.defaultImportance,
            styleInformation: BigTextStyleInformation(daily.verse.pulaar),
          ),
          iOS: const DarwinNotificationDetails(),
        );

        await _plugin.zonedSchedule(
          id: _firstId + i,
          scheduledDate: day,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: 'Maande hannde · ${daily.reference}',
          body: daily.verse.pulaar,
          payload: 'surah:${daily.surah.number}:${daily.surah.verses.indexOf(daily.verse)}',
        );
      }
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }
}
