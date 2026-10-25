import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../services/settings_service.dart';
import 'quran_sync_service.dart';

/// Source unique des sourates affichées. Le texte vient de Supabase (quran_sync),
/// gardé en copie locale : affichage immédiat depuis la copie, puis synchronisation
/// légère en arrière-plan (seuls les versets corrigés sont téléchargés).
class QuranService extends GetxService {
  /// Toutes les sourates disponibles, triées 1 → 114.
  List<SurahModel> _canonical = [];

  /// Sourates dans l'ordre d'affichage choisi par l'utilisateur.
  final _surahs = <SurahModel>[].obs;
  final _currentSurah = Rxn<SurahModel>();
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final isInitialized = false.obs;

  final SettingsService _settingsService;
  final QuranSyncService _sync;
  final _connectivity = Connectivity();

  Future<void>? _loadFuture;
  Future<void>? _syncFuture;
  DateTime? _lastSync;
  AppLifecycleListener? _lifecycleListener;

  QuranService({required SettingsService settingsService, required QuranSyncService syncService})
      : _settingsService = settingsService,
        _sync = syncService;

  List<SurahModel> get surahs => _surahs;
  RxList<SurahModel> get surahsRx => _surahs;
  SurahModel? get currentSurah => _currentSurah.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();

    ever(_settingsService.isActivatedRx, (_) => loadSurahs(force: true));
    ever(_settingsService.surahOrderRx, (_) => _applyOrder());
    _lifecycleListener = AppLifecycleListener(onResume: () {
      final last = _lastSync;
      if (last == null || DateTime.now().difference(last) > kContentRefreshInterval) {
        _syncInBackground();
      }
    });

    _settingsService.ready.then((_) async {
      await loadSurahs();
      isInitialized.value = true;
    });
  }

  @override
  void onClose() {
    _lifecycleListener?.dispose();
    super.onClose();
  }

  /// Charge les sourates. Plusieurs appels simultanés partagent le même chargement ;
  /// sans [force], ne fait rien si les sourates sont déjà chargées.
  Future<void> loadSurahs({bool force = false}) {
    if (!force && _canonical.isNotEmpty) return Future.value();
    return _loadFuture ??= _load().whenComplete(() => _loadFuture = null);
  }

  Future<void> _load() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final local = await _sync.loadLocal();
      final activated = _settingsService.isActivated;

      // Copie locale à jour avec l'état d'activation : affichage immédiat.
      if (!local.isEmpty && local.activated == activated) {
        _setSurahs(local.toModels());
        _syncInBackground();
        return;
      }

      // Première ouverture, ou activation qui vient de changer : synchro maintenant.
      try {
        await _syncNow();
        if (!_sync.snapshot.isEmpty) return;
      } catch (e) {
        debugPrint('Quran sync failed: $e');
      }

      // Hors ligne : ce qu'on a localement, sans jamais montrer de contenu payant
      // à un appareil qui n'est plus activé.
      if (!local.isEmpty && (activated || !local.activated)) {
        _setSurahs(local.toModels());
      } else {
        _setSurahs(await _loadFreeSurahs());
      }
    } catch (e) {
      debugPrint('Error loading surahs: $e');
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _syncNow() => _syncFuture ??= () async {
        try {
          final changed = await _sync.sync();
          _lastSync = DateTime.now();
          if (changed || _canonical.isEmpty) _setSurahs(_sync.snapshot.toModels());
        } finally {
          _syncFuture = null;
        }
      }();

  Future<void> _syncInBackground() async {
    if (await _connectivity.checkConnectivity() == ConnectivityResult.none) return;
    try {
      await _syncNow();
    } catch (e) {
      debugPrint('Background Quran sync failed: $e');
    }
  }

  Future<List<SurahModel>> _loadFreeSurahs() async {
    final String jsonString = await rootBundle.loadString('assets/data/surahs.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> surahsJson = jsonData['surahs'];
    return surahsJson.map((surah) => SurahModel.fromJson(surah)).toList();
  }

  /// Mode correcteur : remplace la traduction d'un verset à l'écran et dans la copie
  /// locale (la base est déjà à jour).
  Future<void> applyCorrection(int surahNumber, int verseNumber, String pulaar) async {
    await _sync.applyCorrection(surahNumber, verseNumber, pulaar);
    final surah = byNumber(surahNumber);
    final i = surah?.verses.indexWhere((v) => v.number == verseNumber) ?? -1;
    if (surah == null || i < 0) return;
    final old = surah.verses[i];
    surah.verses[i] = VerseModel(number: old.number, arabic: old.arabic, pulaar: pulaar);
    _surahs.refresh();
  }

  void _setSurahs(List<SurahModel> surahs) {
    _canonical = [...surahs]..sort((a, b) => a.number.compareTo(b.number));
    _applyOrder();
  }

  void _applyOrder() {
    _surahs.value = _settingsService.surahOrder == SurahOrder.ascending
        ? [..._canonical]
        : _canonical.reversed.toList();
  }

  SurahModel? byNumber(int number) =>
      _canonical.firstWhereOrNull((s) => s.number == number);

  /// Sourate réservée aux utilisateurs activés.
  bool isLocked(SurahModel surah) =>
      !_settingsService.isActivated && !kFreeSurahs.contains(surah.number);

  /// Sourates accessibles, dans l'ordre d'affichage.
  List<SurahModel> get accessibleSurahs =>
      _surahs.where((s) => !isLocked(s)).toList();

  /// Sourate suivante dans l'ordre d'affichage (verrouillées exclues).
  SurahModel? nextOf(int number) {
    final list = accessibleSurahs;
    final i = list.indexWhere((s) => s.number == number);
    return (i >= 0 && i < list.length - 1) ? list[i + 1] : null;
  }

  /// Sourate précédente dans l'ordre d'affichage (verrouillées exclues).
  SurahModel? previousOf(int number) {
    final list = accessibleSurahs;
    final i = list.indexWhere((s) => s.number == number);
    return i > 0 ? list[i - 1] : null;
  }

  void setCurrentSurah(SurahModel surah) {
    _currentSurah.value = surah;
  }
}
