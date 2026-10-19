import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../features/surah/models/surah.dart';

class CacheService extends GetxService {
  static const String surahsBoxName = 'surahs';
  static const String metadataBoxName = 'metadata';
  static const String _lastSyncKey = 'last_sync';
  late Box<Surah> _surahsBox;
  late Box<DateTime> _metadataBox;

  CacheService() {
    _surahsBox = Hive.box<Surah>(surahsBoxName);
    _metadataBox = Hive.box<DateTime>(metadataBoxName);
  }

  Future<void> cacheSurahs(List<Surah> surahs) async {
    await _surahsBox.putAll({for (final s in surahs) s.number: s});
    await _metadataBox.put(_lastSyncKey, DateTime.now());
  }

  List<Surah> getCachedSurahs() {
    return _surahsBox.values.toList();
  }

  DateTime? getLastSyncTime() {
    return _metadataBox.get(_lastSyncKey);
  }

  /// Temps écoulé depuis la dernière synchro réussie (très grand si jamais synchronisé).
  Duration getTimeSinceLastSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return const Duration(days: 999);
    return DateTime.now().difference(lastSync);
  }
}
