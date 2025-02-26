import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/surah/models/surah.dart';
import 'cache_service.dart';

class FirebaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = Get.find<CacheService>();

  Future<List<Surah>> getAllSurahs() async {
    try {
      // Check cache first
      if (!_cacheService.shouldRefreshCache()) {
        final cachedSurahs = _cacheService.getCachedSurahs();
        if (cachedSurahs.isNotEmpty) {
          return cachedSurahs;
        }
      }

      // If cache is empty or outdated, fetch from Firebase
      final QuerySnapshot snapshot = await _firestore
          .collection('sourates')
          .orderBy('suratNumber')
          .get();

      final surahs = snapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
      
      // Update cache
      await _cacheService.cacheSurahs(surahs);
      
      return surahs;
    } catch (e) {
      print('Error fetching surahs: $e');
      // Return cached data if available, even if outdated
      return _cacheService.getCachedSurahs();
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

      final QuerySnapshot snapshot = await _firestore
          .collection('sourates')
          .where('suratNumber', isEqualTo: number)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return Surah.fromFirestore(snapshot.docs.first);
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
