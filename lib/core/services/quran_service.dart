import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../services/firebase_service.dart';
import '../services/settings_service.dart';
import '../services/cache_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QuranService extends GetxService {
  final _surahs = <SurahModel>[].obs;
  final _currentSurah = Rxn<SurahModel>();
  final _currentVerseIndex = 0.obs;
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _settingsInitialized = false.obs;
  final _isSyncing = false.obs;
  final isInitialized = false.obs;

  final FirebaseService _firebaseService;
  final SettingsService _settingsService;
  final CacheService _cacheService;
  final _connectivity = Connectivity();
  Timer? _syncCheckTimer;

  QuranService({
    required FirebaseService firebaseService,
    required SettingsService settingsService,
    required CacheService cacheService,
  }) : _firebaseService = firebaseService,
       _settingsService = settingsService,
       _cacheService = cacheService {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await loadSurahs();
      isInitialized.value = true;
    } catch (e) {
      print('Error initializing QuranService: $e');
      // Retry initialization after a delay
      Future.delayed(const Duration(seconds: 1), _initialize);
    }
  }

  List<SurahModel> get surahs => _surahs;
  SurahModel? get currentSurah => _currentSurah.value;
  int get currentVerseIndex => _currentVerseIndex.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  bool get settingsInitialized => _settingsInitialized.value;
  bool get isSyncing => _isSyncing.value;

  Future<void> loadSurahs({bool forceSync = false}) async {
    if (!_settingsInitialized.value) {
      print('Settings not initialized yet, deferring surah load');
      return;
    }

    try {
      _isLoading.value = true;
      _error.value = null;

      if (_settingsService.isActivated) {
        print('Device is activated, attempting to load from Firebase...');
        try {
          _isSyncing.value = forceSync;
          final firebaseSurahs = await _firebaseService.getAllSurahs();
          if (firebaseSurahs.isNotEmpty) {
            print('Successfully loaded ${firebaseSurahs.length} surahs from Firebase/cache');
            _surahs.value = firebaseSurahs.map((surah) => SurahModel.fromFirebase(surah)).toList();
            _isLoading.value = false;
            _isSyncing.value = false;
            return;
          }
          print('No surahs found in Firebase/cache');
        } catch (e) {
          print('Error loading from Firebase: $e');
          _isSyncing.value = false;
          // Start background retry after a delay
          Future.delayed(const Duration(seconds: 2), _retryFirebaseLoad);
        }
      } else {
        print('Device is not activated, loading free surahs from local JSON...');
      }

      // Load from local JSON if:
      // 1. Device is not activated (free mode)
      // 2. Firebase load failed
      // 3. Firebase returned empty results
      print('Loading from local JSON...');
      final ByteData data = await rootBundle.load('assets/data/surahs.json');
      final String jsonString = utf8.decode(data.buffer.asUint8List());

      final Map<String, dynamic> jsonData = json.decode(jsonString);
      if (!jsonData.containsKey('surahs')) {
        throw 'Invalid JSON format: missing "surahs" key';
      }

      final List<dynamic> surahsData = List.from(jsonData['surahs']);

      // Sort after filtering to maintain correct order
      //surahsData.sort((a, b) => (b['number'] as int).compareTo(a['number'] as int)); // Sort descending

      _surahs.value = surahsData.map((surah) {
        final model = SurahModel.fromJson(surah);
        return model;
      }).toList();

      print('Loaded ${_surahs.length} surahs from local JSON');
    } catch (e, stackTrace) {
      print('Error loading surahs: $e');
      print('Stack trace: $stackTrace');
      _error.value = 'Failed to load surahs: $e';
    } finally {
      _isLoading.value = false;
      _isSyncing.value = false;
    }
  }

  Future<void> _retryFirebaseLoad() async {
    if (!_settingsService.isActivated || !_settingsInitialized.value) return;

    try {
      print('Retrying Firebase load...');
      _isSyncing.value = true;
      final firebaseSurahs = await _firebaseService.getAllSurahs();
      if (firebaseSurahs.isNotEmpty) {
        print('Successfully loaded ${firebaseSurahs.length} surahs from Firebase on retry');
        _surahs.value = firebaseSurahs.map((surah) => SurahModel.fromFirebase(surah)).toList();
      } else {
        print('Firebase retry returned no surahs');
      }
    } catch (e) {
      print('Firebase retry failed: $e');
    } finally {
      _isSyncing.value = false;
    }
  }

  List<SurahModel> searchSurahs(String query) {
    if (query.isEmpty) return [];

    final lowercaseQuery = query.toLowerCase();
    return _surahs.where((surah) {
      final numberMatch = surah.number.toString().contains(query);
      final nameMatch = surah.namePulaar.toLowerCase().contains(lowercaseQuery) ||
                       surah.nameArabic.contains(query);

      // Also search in verses if there's a match in the text or translation
      final versesMatch = surah.verses.any((verse) =>
        verse.pulaar.toLowerCase().contains(lowercaseQuery) ||
        verse.arabic.contains(query)
      );

      return numberMatch || nameMatch || versesMatch;
    }).toList();
  }

  void setCurrentSurah(SurahModel surah) {
    _currentSurah.value = surah;
    _currentVerseIndex.value = 0;
  }

  void setCurrentVerse(int index) {
    if (currentSurah != null && index >= 0 && index < currentSurah!.verses.length) {
      _currentVerseIndex.value = index;
    }
  }

  void nextVerse() {
    if (currentSurah != null && currentVerseIndex < currentSurah!.verses.length - 1) {
      _currentVerseIndex.value++;
    }
  }

  void previousVerse() {
    if (currentSurah != null && currentVerseIndex > 0) {
      _currentVerseIndex.value--;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Listen to activation status changes
    ever(_settingsService.isActivatedRx, (bool activated) {
      print('Activation status changed: $activated');
      if (activated && _settingsInitialized.value) {
        print('Device activated, reloading surahs...');
        loadSurahs();
      }
    });

    // Setup periodic sync check for activated users
    _setupPeriodicSyncCheck();

    // Try to load immediately if settings are already initialized
    if (_settingsService.isActivated) {
      print('Settings already initialized on QuranService init');
      onSettingsInitialized();
    }
  }

  @override
  void onClose() {
    _syncCheckTimer?.cancel();
    super.onClose();
  }

  void _setupPeriodicSyncCheck() {
    // Check every 30 minutes if we need to sync
    _syncCheckTimer?.cancel();
    _syncCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      if (!_settingsService.isActivated) return;

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return;

      final timeSinceLastSync = _cacheService.getTimeSinceLastSync();
      if (timeSinceLastSync.inHours >= 6) {
        print('Periodic sync check: Last sync was ${timeSinceLastSync.inHours} hours ago, initiating sync...');
        loadSurahs(forceSync: true);
      }
    });
  }

  void onSettingsInitialized() {
    print('Settings initialized, activation status: ${_settingsService.isActivated}');
    _settingsInitialized.value = true;
    loadSurahs();
  }
}
