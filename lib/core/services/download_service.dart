import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';

/// Téléchargement des sourates pour l'écoute hors ligne.
/// Chaque fichier est écrit dans « N.mp3.part », vérifié (taille attendue),
/// puis renommé en « N.mp3 » : un fichier interrompu n'est jamais lu comme complet.
class DownloadService extends GetxService {
  static const int _maxConcurrent = 2;
  static const _sizesKey = 'download_sizes';
  static const _wifiOnlyKey = 'download_wifi_only';

  final _dio = Dio();
  final RxSet<int> _downloaded = <int>{}.obs;
  final RxSet<int> _downloading = <int>{}.obs;
  final RxMap<int, double> _progress = <int, double>{}.obs;
  final RxBool wifiOnly = false.obs;

  /// Sourates en attente de réseau (Wi-Fi seulement, ou hors ligne).
  final RxSet<int> waiting = <int>{}.obs;

  final Queue<SurahModel> _queue = Queue();
  final Map<int, CancelToken> _cancelTokens = {};
  final Map<int, Completer<bool>> _completers = {};
  final Map<int, int> _expectedSizes = {};
  final Map<int, int> _remoteSizes = {};
  int _running = 0;
  SharedPreferences? _prefs;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  late final Future<void> _ready = _init();

  @override
  void onInit() {
    super.onInit();
    _ready;
    _connectivitySub = Connectivity().onConnectivityChanged.listen((_) => _pump());
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  Future<Directory> get _dir async {
    final base = Platform.isIOS
        ? await getApplicationSupportDirectory()
        : await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/audio_downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(int surahNumber) async =>
      File('${(await _dir).path}${Platform.pathSeparator}$surahNumber.mp3');

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      wifiOnly.value = _prefs!.getBool(_wifiOnlyKey) ?? false;
      final raw = _prefs!.getString(_sizesKey);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>)
            .forEach((k, v) => _expectedSizes[int.parse(k)] = v as int);
      }

      for (final entity in (await _dir).listSync()) {
        if (entity is! File) continue;
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.endsWith('.part')) {
          await entity.delete(); // téléchargement interrompu
          continue;
        }
        final number = int.tryParse(name.replaceAll('.mp3', ''));
        if (number == null || !name.endsWith('.mp3')) continue;
        final expected = _expectedSizes[number];
        if (expected != null && await entity.length() != expected) {
          await entity.delete(); // fichier incomplet (ancienne version)
          continue;
        }
        _downloaded.add(number);
      }
    } catch (e) {
      debugPrint('Error initializing DownloadService: $e');
    }
  }

  Future<void> _saveSizes() async {
    await _prefs?.setString(
        _sizesKey, jsonEncode(_expectedSizes.map((k, v) => MapEntry('$k', v))));
  }

  bool isDownloaded(int surahNumber) => _downloaded.contains(surahNumber);
  bool isDownloading(int surahNumber) =>
      _downloading.contains(surahNumber) || _queue.any((s) => s.number == surahNumber);
  double getProgress(int surahNumber) => _progress[surahNumber] ?? 0.0;
  Set<int> get downloadedSurahs => _downloaded.toSet();
  RxSet<int> get downloadedRx => _downloaded;

  Future<String?> getOfflineUrl(int surahNumber) async {
    await _ready;
    if (!_downloaded.contains(surahNumber)) return null;
    final file = await _file(surahNumber);
    return await file.exists() ? file.path : null;
  }

  Future<void> setWifiOnly(bool value) async {
    wifiOnly.value = value;
    await _prefs?.setBool(_wifiOnlyKey, value);
    _pump();
  }

  /// Ajoute la sourate à la file. Le Future se termine quand elle est
  /// téléchargée (true) ou en cas d'échec / annulation (false).
  Future<bool> downloadSurah(SurahModel surah) async {
    await _ready;
    if (isDownloaded(surah.number)) return true;
    if (surah.audioUrl.isEmpty) return false;
    final completer = _completers.putIfAbsent(surah.number, () {
      _queue.add(surah);
      _progress[surah.number] = 0.0;
      return Completer<bool>();
    });
    _pump();
    return completer.future;
  }

  void downloadAll(List<SurahModel> surahs) {
    for (final s in surahs) {
      if (!isDownloaded(s.number)) downloadSurah(s);
    }
  }

  Future<bool> _networkAllowed() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) return false;
    if (!wifiOnly.value) return true;
    return result == ConnectivityResult.wifi || result == ConnectivityResult.ethernet;
  }

  Future<void> _pump() async {
    if (_queue.isEmpty || _running >= _maxConcurrent) return;
    if (!await _networkAllowed()) {
      waiting.assignAll(_queue.map((s) => s.number));
      return;
    }
    waiting.clear();
    while (_queue.isNotEmpty && _running < _maxConcurrent) {
      _running++;
      final surah = _queue.removeFirst();
      _download(surah).whenComplete(() {
        _running--;
        _pump();
      });
    }
  }

  Future<void> _download(SurahModel surah) async {
    final n = surah.number;
    final token = CancelToken();
    _cancelTokens[n] = token;
    _downloading.add(n);
    final file = await _file(n);
    final part = File('${file.path}.part');
    var ok = false;
    try {
      final response = await _dio.download(
        surah.audioUrl,
        part.path,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (total > 0) _progress[n] = received / total;
        },
      );
      final expected = int.tryParse(response.headers.value('content-length') ?? '');
      final actual = await part.length();
      if (expected != null && expected != actual) {
        throw StateError('Incomplete download: $actual / $expected bytes');
      }
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      _expectedSizes[n] = actual;
      await _saveSizes();
      _downloaded.add(n);
      _progress[n] = 1.0;
      ok = true;
    } catch (e) {
      if (e is! DioException || !CancelToken.isCancel(e)) {
        debugPrint('Error downloading surah $n: $e');
      }
      if (await part.exists()) await part.delete();
      _progress.remove(n);
    } finally {
      _downloading.remove(n);
      _cancelTokens.remove(n);
      _completers.remove(n)?.complete(ok);
    }
  }

  void cancel(int surahNumber) {
    _queue.removeWhere((s) => s.number == surahNumber);
    waiting.remove(surahNumber);
    _cancelTokens[surahNumber]?.cancel();
    if (!_downloading.contains(surahNumber)) {
      _progress.remove(surahNumber);
      _completers.remove(surahNumber)?.complete(false);
    }
  }

  void cancelAll() {
    for (final n in [..._queue.map((s) => s.number), ..._cancelTokens.keys]) {
      cancel(n);
    }
  }

  Future<bool> deleteSurah(int surahNumber) async {
    try {
      cancel(surahNumber);
      final file = await _file(surahNumber);
      if (await file.exists()) await file.delete();
      _downloaded.remove(surahNumber);
      _progress.remove(surahNumber);
      _expectedSizes.remove(surahNumber);
      await _saveSizes();
      return true;
    } catch (e) {
      debugPrint('Error deleting surah $surahNumber: $e');
      return false;
    }
  }

  Future<void> deleteAll() async {
    cancelAll();
    for (final n in _downloaded.toList()) {
      await deleteSurah(n);
    }
  }

  /// Taille d'un fichier téléchargé, en octets (0 s'il n'existe pas).
  Future<int> fileSize(int surahNumber) async {
    final file = await _file(surahNumber);
    return await file.exists() ? await file.length() : 0;
  }

  Future<int> totalBytesOnDisk() async {
    var total = 0;
    for (final n in _downloaded) {
      total += await fileSize(n);
    }
    return total;
  }

  /// Taille du fichier distant (requête HEAD, mise en cache), ou null si inconnue.
  Future<int?> remoteSize(SurahModel surah) async {
    if (_remoteSizes.containsKey(surah.number)) return _remoteSizes[surah.number];
    try {
      final response = await _dio.head(surah.audioUrl);
      final size = int.tryParse(response.headers.value('content-length') ?? '');
      if (size != null) _remoteSizes[surah.number] = size;
      return size;
    } catch (_) {
      return null;
    }
  }
}
