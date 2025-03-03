import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../services/firebase_service.dart';
import '../services/settings_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class QuranService extends GetxService {
  final _surahs = <SurahModel>[].obs;
  final _currentSurah = Rxn<SurahModel>();
  final _currentVerseIndex = 0.obs;
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _settingsInitialized = false.obs;

  final FirebaseService _firebaseService;
  final SettingsService _settingsService;

  QuranService({
    required FirebaseService firebaseService,
    required SettingsService settingsService,
  }) : _firebaseService = firebaseService,
       _settingsService = settingsService;

  List<SurahModel> get surahs => _surahs;
  SurahModel? get currentSurah => _currentSurah.value;
  int get currentVerseIndex => _currentVerseIndex.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

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
    
    // Try to load immediately if settings are already initialized
    if (_settingsService.isActivated) {
      print('Settings already initialized on QuranService init');
      onSettingsInitialized();
    }
  }

  void onSettingsInitialized() {
    print('Settings initialized, activation status: ${_settingsService.isActivated}');
    _settingsInitialized.value = true;
    loadSurahs();
  }

  Future<void> loadSurahs() async {
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
          final firebaseSurahs = await _firebaseService.getAllSurahs();
          if (firebaseSurahs.isNotEmpty) {
            print('Successfully loaded ${firebaseSurahs.length} surahs from Firebase/cache');
            _surahs.value = firebaseSurahs.map((surah) => SurahModel.fromFirebase(surah)).toList();
            _isLoading.value = false;
            return;
          }
          print('No surahs found in Firebase/cache');
        } catch (e) {
          print('Error loading from Firebase: $e');
          // Start background retry after a delay
          Future.delayed(const Duration(seconds: 2), _retryFirebaseLoad);
        }
      } else {
        print('Device is not activated, using local JSON');
      }
      
      // Load from local JSON if:
      // 1. Device is not activated
      // 2. Firebase load failed
      // 3. Firebase returned empty results
      if (_surahs.isEmpty) {
        print('Loading from local JSON...');
        final ByteData data = await rootBundle.load('assets/data/surahs.json');
        final String jsonString = utf8.decode(data.buffer.asUint8List());
        
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        if (!jsonData.containsKey('surahs')) {
          throw 'Invalid JSON format: missing "surahs" key';
        }

        final List<dynamic> surahsData = jsonData['surahs'];
        _surahs.value = surahsData.map((surah) {
          final model = SurahModel.fromJson(surah);
          return model;
        }).toList();

        print('Loaded ${_surahs.length} surahs from local JSON');
      }
    } catch (e, stackTrace) {
      print('Error loading surahs: $e');
      print('Stack trace: $stackTrace');
      _error.value = 'Failed to load surahs: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _retryFirebaseLoad() async {
    if (!_settingsService.isActivated || !_settingsInitialized.value) return;

    try {
      print('Retrying Firebase load...');
      final firebaseSurahs = await _firebaseService.getAllSurahs();
      if (firebaseSurahs.isNotEmpty) {
        print('Successfully loaded ${firebaseSurahs.length} surahs from Firebase on retry');
        _surahs.value = firebaseSurahs.map((surah) => SurahModel.fromFirebase(surah)).toList();
      } else {
        print('Firebase retry returned no surahs');
      }
    } catch (e) {
      print('Firebase retry failed: $e');
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
}
