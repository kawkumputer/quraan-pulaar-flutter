import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/surah/models/surah.dart';
import 'cache_service.dart';

class FirebaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = Get.find<CacheService>();

  @override
  void onInit() {
    super.onInit();
    // Enable Firestore persistence
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
  }

  Future<List<Surah>> getAllSurahs() async {
    try {
      print('Starting Firebase getAllSurahs...');
      // Check cache first
      if (!_cacheService.shouldRefreshCache()) {
        final cachedSurahs = _cacheService.getCachedSurahs();
        if (cachedSurahs.isNotEmpty) {
          print('Returning ${cachedSurahs.length} surahs from cache');
          return cachedSurahs;
        }
      }

      print('Fetching surahs from Firebase...');
      // Try server first
      try {
        final serverSnapshot = await _firestore
            .collection('sourates')
            .orderBy('suratNumber')
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

      // If server fails or returns empty, try cache
      try {
        final cacheSnapshot = await _firestore
            .collection('sourates')
            .orderBy('suratNumber')
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

      // If both Firebase sources fail, try Hive cache
      final cachedSurahs = _cacheService.getCachedSurahs();
      if (cachedSurahs.isNotEmpty) {
        print('Falling back to ${cachedSurahs.length} surahs from Hive cache');
        return cachedSurahs;
      }

      print('No surahs found in any source');
      return [];
    } catch (e) {
      print('Error in getAllSurahs: $e');
      // Last resort - try Hive cache
      final cachedSurahs = _cacheService.getCachedSurahs();
      if (cachedSurahs.isNotEmpty) {
        print('Returning ${cachedSurahs.length} surahs from Hive cache after error');
        return cachedSurahs;
      }
      throw e; // Re-throw if we have no data at all
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
        .orderBy('suratNumber')
        .snapshots()
        .map((snapshot) {
          final surahs = snapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
          _cacheService.cacheSurahs(surahs); // Update cache when stream receives new data
          return surahs;
        });
  }
}
