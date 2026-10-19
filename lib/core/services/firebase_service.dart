import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/surah/models/surah.dart';
import 'cache_service.dart';

/// Accès Firestore au contenu des sourates. La politique de synchro est
/// décidée par QuranService ; ce service ne lance rien de lui-même.
class FirebaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService;

  FirebaseService({required CacheService cacheService})
      : _cacheService = cacheService;

  @override
  void onInit() {
    super.onInit();
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
    );
  }

  CollectionReference<Map<String, dynamic>> get _sourates =>
      _firestore.collection('sourates');

  /// Contenu local : cache Hive, sinon cache persistant de Firestore. Aucun accès réseau.
  Future<List<Surah>> getLocalSurahs() async {
    final cached = _cacheService.getCachedSurahs();
    if (cached.isNotEmpty) return cached;

    try {
      final snapshot = await _sourates.get(const GetOptions(source: Source.cache));
      if (snapshot.docs.isNotEmpty) {
        final surahs = snapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
        await _cacheService.cacheSurahs(surahs);
        return surahs;
      }
    } catch (_) {
      // Pas de cache Firestore : normal au premier lancement.
    }
    return [];
  }

  /// Télécharge toutes les sourates depuis le serveur et met à jour le cache Hive.
  Future<List<Surah>> fetchFromServer() async {
    final snapshot = await _sourates.get(const GetOptions(source: Source.server));
    final surahs = snapshot.docs.map((doc) => Surah.fromFirestore(doc)).toList();
    if (surahs.isNotEmpty) {
      await _cacheService.cacheSurahs(surahs);
    }
    return surahs;
  }
}
