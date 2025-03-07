import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/surah/models/surah.dart';

class CacheService extends GetxService {
  static const String _surahsBoxName = 'surahs';
  static const String _lastUpdateKey = 'last_update';
  static const String _lastSyncKey = 'last_sync';
  late Box<Surah> _surahsBox;
  late Box<DateTime> _metadataBox;

  // Sync status observable
  final _isSyncing = false.obs;
  bool get isSyncing => _isSyncing.value;

  CacheService() {
    _surahsBox = Hive.box<Surah>(_surahsBoxName);
    _metadataBox = Hive.box('metadata');
  }

  Future<void> cacheSurahs(List<Surah> surahs) async {
    _isSyncing.value = true;
    try {
      await _surahsBox.clear();
      await _surahsBox.addAll(surahs);
      final now = DateTime.now();
      await _metadataBox.put(_lastUpdateKey, now);
      await _metadataBox.put(_lastSyncKey, now);
    } finally {
      _isSyncing.value = false;
    }
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

  DateTime? getLastSyncTime() {
    return _metadataBox.get(_lastSyncKey);
  }

  Duration getTimeSinceLastSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return const Duration(days: 999); // Force sync if never synced
    return DateTime.now().difference(lastSync);
  }

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    if (!_metadataBox.containsKey(_lastUpdateKey)) {
      _metadataBox.put(_lastUpdateKey, now);
    }
    if (!_metadataBox.containsKey(_lastSyncKey)) {
      _metadataBox.put(_lastSyncKey, now);
    }
  }
}
