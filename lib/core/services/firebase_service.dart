import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/surah/models/surah.dart';
import 'cache_service.dart';
import 'settings_service.dart';

class FirebaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService;
  final SettingsService _settingsService;
  Timer? _syncTimer;
  final _syncInterval = const Duration(hours: 6); // Sync every 6 hours

  FirebaseService({
    required CacheService cacheService,
    required SettingsService settingsService,
  }) : _cacheService = cacheService,
       _settingsService = settingsService;

  @override
  void onInit() {
    super.onInit();
    // Enable Firestore persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
    
    // Start periodic sync if activated
    if (_settingsService.isActivated) {
      _startPeriodicSync();
    }

    // Listen to activation status changes
    ever(_settingsService.isActivatedRx, (bool activated) {
      if (activated) {
        _startPeriodicSync();
      } else {
        _syncTimer?.cancel();
      }
    });
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }

  void _startPeriodicSync() {
    // Initial sync
    _performSync();
    
    // Setup periodic sync
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performSync();
    });
  }

  Future<void> _performSync() async {
    try {
      print('Performing periodic sync with Firebase...');
      final serverSnapshot = await _firestore
          .collection('sourates')
          .orderBy('suratNumber', descending: true)
          .get(const GetOptions(source: Source.server));

      if (serverSnapshot.docs.isNotEmpty) {
        print('Synced ${serverSnapshot.docs.length} surahs from Firebase server');
        final surahs = serverSnapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
        await _cacheService.cacheSurahs(surahs);
      }
    } catch (e) {
      print('Periodic sync failed: $e');
    }
  }

  Future<List<Surah>> getAllSurahs() async {
    try {
      print('Starting Firebase getAllSurahs...');
      // Always try server first for activated users
      if (_settingsService.isActivated) {
        try {
          final serverSnapshot = await _firestore
              .collection('sourates')
              .orderBy('suratNumber', descending: true)
              .get(const GetOptions(source: Source.server));

          if (serverSnapshot.docs.isNotEmpty) {
            print('Found ${serverSnapshot.docs.length} surahs from Firebase server');
            final surahs = serverSnapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
            await _cacheService.cacheSurahs(surahs);
            return surahs;
          }
        } catch (serverError) {
          print('Server fetch failed: $serverError, trying cache...');
        }
      }

      // Check cache for non-activated users or if server failed
      final cachedSurahs = _cacheService.getCachedSurahs();
      if (cachedSurahs.isNotEmpty) {
        print('Returning ${cachedSurahs.length} surahs from cache');
        
        // Schedule a background sync if activated
        if (_settingsService.isActivated) {
          _performSync();
        }
        
        return cachedSurahs;
      }

      // If cache is empty, try Firebase cache
      try {
        final cacheSnapshot = await _firestore
            .collection('sourates')
            .orderBy('suratNumber', descending: true)
            .get(const GetOptions(source: Source.cache));
            
        if (cacheSnapshot.docs.isNotEmpty) {
          print('Found ${cacheSnapshot.docs.length} surahs in Firebase cache');
          final surahs = cacheSnapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
          await _cacheService.cacheSurahs(surahs);
          return surahs;
        }
      } catch (cacheError) {
        print('Cache fetch failed: $cacheError');
      }

      print('No surahs found in any source');
      return [];
    } catch (e) {
      print('Error in getAllSurahs: $e');
      throw e;
    }
  }

  Future<Surah?> getSurahByNumber(int number) async {
    try {
      // Check cache first
      final cachedSurahs = _cacheService.getCachedSurahs();
      final cachedSurah = cachedSurahs.where((s) => s.number == number).firstOrNull;
      if (cachedSurah != null) {
        return cachedSurah;
      }

      // Try server first
      try {
        final serverSnapshot = await _firestore
            .collection('sourates')
            .where('suratNumber', isEqualTo: number)
            .limit(1)
            .get(const GetOptions(source: Source.server));

        if (serverSnapshot.docs.isNotEmpty) {
          print('Found surah $number from Firebase server');
          return Surah.fromFirestore(serverSnapshot.docs.first);
        }
      } catch (serverError) {
        print('Server fetch failed: $serverError, trying cache...');
      }

      // If server fails or returns empty, try cache
      try {
        final cacheSnapshot = await _firestore
            .collection('sourates')
            .where('suratNumber', isEqualTo: number)
            .limit(1)
            .get(const GetOptions(source: Source.cache));
            
        if (cacheSnapshot.docs.isNotEmpty) {
          print('Found surah $number in Firebase cache');
          return Surah.fromFirestore(cacheSnapshot.docs.first);
        }
      } catch (cacheError) {
        print('Cache fetch failed: $cacheError');
      }

      print('Surah $number not found in any source');
      return null;
    } catch (e) {
      print('Error fetching surah $number: $e');
      return null;
    }
  }

  Stream<List<Surah>> getSurahsStream() {
    return _firestore
        .collection('sourates')
        .orderBy('suratNumber', descending: true)
        .snapshots()
        .map((snapshot) {
          final surahs = snapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
          _cacheService.cacheSurahs(surahs); // Update cache when stream receives new data
          return surahs;
        });
  }
}
