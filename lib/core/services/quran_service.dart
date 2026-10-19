import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../constants/app_constants.dart';
import '../models/surah_model.dart';
import '../services/firebase_service.dart';
import '../services/settings_service.dart';
import '../services/cache_service.dart';

/// Source unique des sourates affichées : chargement (cache d'abord), rafraîchissement
/// et ordre d'affichage.
class QuranService extends GetxService {
  /// Toutes les sourates disponibles, triées 1 → 114.
  List<SurahModel> _canonical = [];

  /// Sourates dans l'ordre d'affichage choisi par l'utilisateur.
  final _surahs = <SurahModel>[].obs;
  final _currentSurah = Rxn<SurahModel>();
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final isInitialized = false.obs;

  final FirebaseService _firebaseService;
  final SettingsService _settingsService;
  final CacheService _cacheService;
  final _connectivity = Connectivity();

  Future<void>? _loadFuture;
  bool _refreshing = false;
  AppLifecycleListener? _lifecycleListener;

  QuranService({
    required FirebaseService firebaseService,
    required SettingsService settingsService,
    required CacheService cacheService,
  }) : _firebaseService = firebaseService,
       _settingsService = settingsService,
       _cacheService = cacheService;

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
    _lifecycleListener = AppLifecycleListener(onResume: _refreshIfStale);

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
      if (_settingsService.isActivated) {
        final local = await _firebaseService.getLocalSurahs();
        if (local.isNotEmpty) {
          _setSurahs(local.map(SurahModel.fromFirebase).toList());
          _refreshIfStale();
          return;
        }
        try {
          final remote = await _firebaseService.fetchFromServer();
          if (remote.isNotEmpty) {
            _setSurahs(remote.map(SurahModel.fromFirebase).toList());
            return;
          }
        } catch (e) {
          debugPrint('Error loading surahs from Firestore: $e');
        }
        // Pas de cache ni de réseau : on retombe sur les sourates gratuites.
      }

      _setSurahs(await _loadFreeSurahs());
    } catch (e) {
      debugPrint('Error loading surahs: $e');
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<List<SurahModel>> _loadFreeSurahs() async {
    final String jsonString = await rootBundle.loadString('assets/data/surahs.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final List<dynamic> surahsJson = jsonData['surahs'];
    return surahsJson.map((surah) => SurahModel.fromJson(surah)).toList();
  }

  /// Rafraîchit depuis le serveur en arrière-plan si le cache date de plus de 24 h.
  Future<void> _refreshIfStale() async {
    if (_refreshing || !_settingsService.isActivated) return;
    if (_cacheService.getTimeSinceLastSync() < kContentRefreshInterval) return;
    if (await _connectivity.checkConnectivity() == ConnectivityResult.none) return;

    _refreshing = true;
    try {
      final remote = await _firebaseService.fetchFromServer();
      if (remote.isNotEmpty) {
        _setSurahs(remote.map(SurahModel.fromFirebase).toList());
      }
    } catch (e) {
      debugPrint('Background refresh failed: $e');
    } finally {
      _refreshing = false;
    }
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
