import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../services/download_service.dart';
import '../constants/strings.dart';
import '../utils/messenger.dart';

enum AudioContentType { surah, hadith }

/// Seul responsable de la lecture audio. Les sourates sont jouées comme une playlist
/// dans l'ordre d'affichage : l'enchaînement et les boutons de la notification
/// fonctionnent sans navigation. Les écrans observent [currentSurah].
class AudioController extends GetxController {
  final AudioPlayer audioPlayer = AudioPlayer();

  late final QuranService _quranService;
  late final DownloadService _downloadService;

  /// Identifiant de l'élément en cours (numéro de sourate ou id de hadith), -1 si rien.
  final RxInt currentlyPlayingId = RxInt(-1);
  final RxBool isLoading = RxBool(false);
  final RxBool isPlaying = RxBool(false);
  final Rx<AudioContentType> contentType = AudioContentType.surah.obs;
  final Rxn<SurahModel> currentSurah = Rxn<SurahModel>();

  /// Sourates de la playlist en cours, dans l'ordre de lecture.
  List<SurahModel> _queue = [];
  String? _artworkPath;
  final List<StreamSubscription> _subscriptions = [];

  @override
  void onInit() {
    super.onInit();
    _quranService = Get.find<QuranService>();
    _downloadService = Get.find<DownloadService>();
    _prepareArtwork();

    _subscriptions.add(audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
      if (state.processingState == ProcessingState.completed) {
        // Fin de la dernière sourate de la playlist.
        isPlaying.value = false;
      }
    }, onError: _onPlayerError));
    _subscriptions.add(audioPlayer.currentIndexStream.listen(_onIndexChanged, onError: (_) {}));
    // Erreurs de lecture en cours (ex. connexion perdue au milieu d'une sourate).
    _subscriptions.add(audioPlayer.playbackEventStream.listen((_) {}, onError: _onPlayerError));

    // L'ordre ou l'activation a changé : la playlist doit suivre.
    ever(_quranService.surahsRx, (_) => _rebuildQueue());
  }

  @override
  void onClose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    audioPlayer.dispose();
    super.onClose();
  }

  Future<void> _prepareArtwork() async {
    try {
      final bytes = await rootBundle.load('assets/icon/original.png');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/app_icon.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      _artworkPath = file.path;
    } catch (e) {
      debugPrint('Error preparing artwork: $e');
    }
  }

  void _onPlayerError(Object error, [StackTrace? stackTrace]) {
    debugPrint('Player error: $error');
    isPlaying.value = false;
    _showPlaybackError(error);
  }

  /// Lance la lecture sans laisser d'erreur non gérée (elles passent par _onPlayerError).
  void _play() {
    audioPlayer.play().catchError((Object e) => debugPrint('play() failed: $e'));
  }

  Future<bool> _isOffline() async =>
      await Connectivity().checkConnectivity() == ConnectivityResult.none;

  void _onIndexChanged(int? index) {
    if (contentType.value != AudioContentType.surah) return;
    if (index == null || index < 0 || index >= _queue.length) return;
    final surah = _queue[index];
    currentSurah.value = surah;
    currentlyPlayingId.value = surah.number;
    _quranService.setCurrentSurah(surah);
  }

  Uri _uriFor(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) return Uri.parse(pathOrUrl);
    // iOS a besoin du schéma file:// pour les fichiers locaux
    return Platform.isIOS
        ? Uri.parse('file://${File(pathOrUrl).absolute.path}')
        : Uri.file(pathOrUrl);
  }

  Future<AudioSource> _surahSource(SurahModel surah) async {
    final offline = await _downloadService.getOfflineUrl(surah.number);
    return AudioSource.uri(
      _uriFor(offline ?? surah.audioUrl),
      tag: MediaItem(
        id: 'surah-${surah.number}',
        title: surah.namePulaar.isNotEmpty ? surah.namePulaar : 'Simoore ${surah.number}',
        artist: 'Quraan Pulaar',
        album: 'Quraan Pulaar',
        displayTitle: '${surah.namePulaar} - ${surah.nameArabic}',
        artUri: _artworkPath != null ? Uri.file(_artworkPath!) : null,
      ),
    );
  }

  /// Lit [surah] puis enchaîne sur les suivantes dans l'ordre d'affichage.
  Future<void> playSurah(SurahModel surah, {Duration? startAt, bool autoPlay = true}) async {
    try {
      isLoading.value = true;
      contentType.value = AudioContentType.surah;

      final offline = await _isOffline();
      if (offline && !_downloadService.isDownloaded(surah.number)) {
        showMessage(S.noConnectionNotDownloaded, error: true);
        return;
      }

      // Hors ligne : seules les sourates téléchargées peuvent s'enchaîner.
      _queue = _quranService.accessibleSurahs
          .where((s) => s.audioUrl.isNotEmpty)
          .where((s) => !offline || _downloadService.isDownloaded(s.number))
          .toList();
      var index = _queue.indexWhere((s) => s.number == surah.number);
      if (index < 0) {
        _queue = [surah];
        index = 0;
      }

      final sources = await Future.wait(_queue.map(_surahSource));
      await audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: sources),
        initialIndex: index,
        initialPosition: startAt ?? Duration.zero,
      );
      _onIndexChanged(index);

      if (!offline &&
          !_downloadService.isDownloaded(surah.number) &&
          !_downloadService.isDownloading(surah.number)) {
        downloadSurah(surah.number); // en arrière-plan
      }

      if (autoPlay) _play();
    } catch (e) {
      debugPrint('Error playing surah: $e');
      _resetState();
      _showPlaybackError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Reconstruit la playlist en gardant la sourate et la position en cours.
  Future<void> _rebuildQueue() async {
    final surah = currentSurah.value;
    if (contentType.value != AudioContentType.surah || surah == null) return;
    if (audioPlayer.processingState == ProcessingState.idle) return;

    if (_quranService.isLocked(surah)) {
      await stopPlaying();
      return;
    }
    final newOrder = _quranService.accessibleSurahs
        .where((s) => s.audioUrl.isNotEmpty)
        .map((s) => s.number)
        .toList();
    if (listEquals(newOrder, _queue.map((s) => s.number).toList())) return;

    await playSurah(surah, startAt: audioPlayer.position, autoPlay: audioPlayer.playing);
  }

  /// Lecture / pause de [surah] (démarre la playlist si une autre sourate est en cours).
  void toggleSurah(SurahModel surah) {
    final isCurrent = contentType.value == AudioContentType.surah &&
        currentSurah.value?.number == surah.number &&
        audioPlayer.processingState != ProcessingState.idle;
    if (!isCurrent) {
      playSurah(surah);
    } else if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      _play();
    }
  }

  bool get hasNext => audioPlayer.hasNext;
  bool get hasPrevious => audioPlayer.hasPrevious;

  Future<void> skipNext() async {
    if (audioPlayer.hasNext) {
      await audioPlayer.seekToNext();
      _play();
    }
  }

  Future<void> skipPrevious() async {
    if (audioPlayer.hasPrevious) {
      await audioPlayer.seekToPrevious();
      _play();
    }
  }

  /// Lit un élément isolé (hadith).
  Future<void> playUrl(int id, String url, {
    String? surahName,
    String? surahNameArabic,
    AudioContentType contentType = AudioContentType.hadith,
  }) async {
    try {
      isLoading.value = true;
      this.contentType.value = contentType;
      _queue = [];
      currentSurah.value = null;

      await audioPlayer.setAudioSource(AudioSource.uri(
        _uriFor(url),
        tag: MediaItem(
          id: 'hadith-$id',
          title: surahName ?? 'Hadiis $id',
          artist: 'Quraan Pulaar',
          album: 'Hadiisaaji',
          artUri: _artworkPath != null ? Uri.file(_artworkPath!) : null,
        ),
      ));
      currentlyPlayingId.value = id;
      _play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
      _resetState();
      _showPlaybackError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void togglePlay(int id, String url, {
    String? surahName,
    String? surahNameArabic,
    AudioContentType contentType = AudioContentType.hadith,
  }) {
    if (this.contentType.value == contentType && currentlyPlayingId.value == id) {
      audioPlayer.playing ? audioPlayer.pause() : _play();
    } else {
      playUrl(id, url, surahName: surahName, surahNameArabic: surahNameArabic, contentType: contentType);
    }
  }

  Future<void> pause() async {
    await audioPlayer.pause();
  }

  Future<void> stopPlaying() async {
    try {
      await audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    _resetState();
  }

  void _resetState() {
    currentlyPlayingId.value = -1;
    currentSurah.value = null;
    isPlaying.value = false;
    _queue = [];
  }

  void _showPlaybackError([Object? error]) {
    final text = error.toString();
    final network = text.contains('UnknownHost') ||
        text.contains('SocketException') ||
        text.contains('Connection');
    showMessage(
      network
          ? S.noConnection
          : 'Roŋki aawtaade ${contentType.value == AudioContentType.surah ? "simoore" : "hadiisa"} nde',
      error: true,
    );
  }

  bool isSurahDownloaded(int surahNumber) {
    return _downloadService.isDownloaded(surahNumber);
  }

  bool isSurahDownloading(int surahNumber) {
    return _downloadService.isDownloading(surahNumber);
  }

  double getSurahDownloadProgress(int surahNumber) {
    return _downloadService.getProgress(surahNumber);
  }

  Future<bool> downloadSurah(int surahNumber) async {
    final surah = _quranService.byNumber(surahNumber);
    if (surah == null) return false;
    try {
      return await _downloadService.downloadSurah(surah);
    } catch (e) {
      debugPrint('Error downloading surah: $e');
      return false;
    }
  }

  Future<void> deleteSurah(int surahNumber) async {
    try {
      await _downloadService.deleteSurah(surahNumber);
    } catch (e) {
      debugPrint('Error deleting surah: $e');
    }
  }
}
