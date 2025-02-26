import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/surah/models/surah.dart';

class CacheService extends GetxService {
  static const String _surahsBoxName = 'surahs';
  static const String _lastUpdateKey = 'last_update';
  late Box<Surah> _surahsBox;
  late Box<DateTime> _metadataBox;

  CacheService() {
    _surahsBox = Hive.box<Surah>(_surahsBoxName);
    _metadataBox = Hive.box('metadata');
  }

  Future<void> cacheSurahs(List<Surah> surahs) async {
    await _surahsBox.clear();
    await _surahsBox.addAll(surahs);
    await _metadataBox.put(_lastUpdateKey, DateTime.now());
  }

  List<Surah> getCachedSurahs() {
    return _surahsBox.values.toList();
  }

  bool shouldRefreshCache() {
    final lastUpdate = _metadataBox.get(_lastUpdateKey);
    if (lastUpdate == null) return true;
    
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inHours >= 24; // Refresh cache if it's older than 24 hours
  }

  @override
  void onInit() {
    super.onInit();
    if (!_metadataBox.containsKey(_lastUpdateKey)) {
      _metadataBox.put(_lastUpdateKey, DateTime.now());
    }
  }
}
