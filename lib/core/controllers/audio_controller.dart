import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../services/download_service.dart';
import '../constants/strings.dart';
import '../utils/messenger.dart';
import '../utils/verse_timing.dart';

enum AudioContentType { surah, hadith }

/// Répétition : aucune, la sourate en cours, ou le verset en cours (position estimée).
enum AudioRepeat { off, surah, verse }

/// Élément d'une playlist de hadiths.
typedef HadithItem = ({int id, String url});

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

  /// Vitesse de lecture (mémorisée).
  final RxDouble speed = 1.0.obs;
  final Rx<AudioRepeat> repeatMode = AudioRepeat.off.obs;

  /// Minuterie de veille : heure de mise en pause, ou fin de l'élément en cours.
  final Rxn<DateTime> sleepAt = Rxn<DateTime>();
  final RxBool sleepAtEndOfItem = false.obs;
  Timer? _sleepTimer;

  /// Verset répété (index) quand [repeatMode] vaut verse.
  int? _repeatVerseIndex;
  VerseTiming? _repeatTiming;
  int? _lastIndex;

  /// Sourates de la playlist en cours, dans l'ordre de lecture.
  List<SurahModel> _queue = [];
  List<HadithItem> _hadithQueue = [];
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
        _clearSleepTimer();
      }
    }, onError: _onPlayerError));
    _subscriptions.add(audioPlayer.positionStream.listen(_onPosition, onError: (_) {}));
    _loadSpeed();
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
    if (index == null) return;
    final itemChanged = _lastIndex != null && _lastIndex != index;
    _lastIndex = index;
    if (itemChanged) {
      // Minuterie « fin de l'élément » : on s'arrête au passage au suivant.
      if (sleepAtEndOfItem.value) {
        audioPlayer.pause();
        _clearSleepTimer();
      }
      if (repeatMode.value == AudioRepeat.verse) setRepeatMode(AudioRepeat.off);
    }

    if (contentType.value == AudioContentType.hadith) {
      if (index >= 0 && index < _hadithQueue.length) {
        currentlyPlayingId.value = _hadithQueue[index].id;
      }
      return;
    }
    if (index < 0 || index >= _queue.length) return;
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
        title: surah.namePulaar.isNotEmpty ? S.surahName(surah) : S.surahN(surah.number),
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
      _hadithQueue = [];
      _lastIndex = null;

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

      if (autoPlay) _play();
    } catch (e) {
      debugPrint('Error playing surah: $e');
      _resetState();
      _showPlaybackError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Lit [surah] à partir du verset [verseIndex] (position estimée, voir VerseTiming).
  Future<void> playFromVerse(SurahModel surah, int verseIndex) async {
    final isCurrent = contentType.value == AudioContentType.surah &&
        currentSurah.value?.number == surah.number &&
        audioPlayer.duration != null;
    if (!isCurrent) {
      await playSurah(surah, autoPlay: false);
      if (currentSurah.value?.number != surah.number) return; // échec (hors ligne...)
    }
    try {
      final duration = audioPlayer.duration ??
          await audioPlayer.durationStream
              .firstWhere((d) => d != null)
              .timeout(const Duration(seconds: 15));
      await audioPlayer.seek(VerseTiming(surah, duration!).startOf(verseIndex));
    } catch (e) {
      debugPrint('Could not seek to verse: $e');
    }
    _play();
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

  /// Lit les hadiths [items] à partir de [index] (playlist : précédent / suivant).
  Future<void> playHadiths(List<HadithItem> items, int index) async {
    try {
      isLoading.value = true;
      contentType.value = AudioContentType.hadith;
      _queue = [];
      currentSurah.value = null;
      _hadithQueue = items;
      _lastIndex = null;
      if (repeatMode.value == AudioRepeat.verse) setRepeatMode(AudioRepeat.off);

      await audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: [
          for (final h in items)
            AudioSource.uri(
              _uriFor(h.url),
              tag: MediaItem(
                id: 'hadith-${h.id}',
                title: S.hadithN(h.id),
                artist: 'Quraan Pulaar',
                album: S.hadithsTitle,
                artUri: _artworkPath != null ? Uri.file(_artworkPath!) : null,
              ),
            ),
        ]),
        initialIndex: index,
      );
      _onIndexChanged(index);
      _play();
    } catch (e) {
      debugPrint('Error playing hadiths: $e');
      _resetState();
      _showPlaybackError(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Lecture / pause du hadith [index] de [items].
  void toggleHadith(List<HadithItem> items, int index) {
    final isCurrent = contentType.value == AudioContentType.hadith &&
        currentlyPlayingId.value == items[index].id &&
        audioPlayer.processingState != ProcessingState.idle;
    if (!isCurrent) {
      playHadiths(items, index);
    } else if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      _play();
    }
  }

  // ---------------------------------------------------------------------------
  // Vitesse, répétition, minuterie
  // ---------------------------------------------------------------------------

  static const _speedKey = 'playback_speed';

  Future<void> _loadSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    await setSpeed(prefs.getDouble(_speedKey) ?? 1.0, save: false);
  }

  Future<void> setSpeed(double value, {bool save = true}) async {
    speed.value = value;
    await audioPlayer.setSpeed(value);
    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_speedKey, value);
    }
  }

  void setRepeatMode(AudioRepeat mode) {
    repeatMode.value = mode;
    audioPlayer.setLoopMode(mode == AudioRepeat.surah ? LoopMode.one : LoopMode.off);
    _repeatVerseIndex = null;
    _repeatTiming = null;
    if (mode == AudioRepeat.verse) {
      final surah = currentSurah.value;
      final duration = audioPlayer.duration;
      if (contentType.value != AudioContentType.surah || surah == null || duration == null) {
        repeatMode.value = AudioRepeat.off;
        return;
      }
      final timing = VerseTiming(surah, duration);
      if (timing.length == 0) {
        repeatMode.value = AudioRepeat.off;
        return;
      }
      _repeatTiming = timing;
      _repeatVerseIndex = timing.indexAt(audioPlayer.position).clamp(0, timing.length - 1);
    }
  }

  /// Répétition du verset : retour à son début quand on atteint sa fin.
  void _onPosition(Duration position) {
    final index = _repeatVerseIndex;
    final timing = _repeatTiming;
    if (repeatMode.value != AudioRepeat.verse || index == null || timing == null) return;
    if (position >= timing.endOf(index) - const Duration(milliseconds: 200)) {
      audioPlayer.seek(timing.startOf(index));
    }
  }

  /// Met en pause après [duration], ou à la fin de l'élément en cours si null.
  void setSleepTimer(Duration? duration) {
    _clearSleepTimer();
    if (duration == null) {
      sleepAtEndOfItem.value = true;
      return;
    }
    sleepAt.value = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () {
      audioPlayer.pause();
      _clearSleepTimer();
    });
  }

  void cancelSleepTimer() => _clearSleepTimer();

  void _clearSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    sleepAt.value = null;
    sleepAtEndOfItem.value = false;
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
    _hadithQueue = [];
    _lastIndex = null;
    if (repeatMode.value == AudioRepeat.verse) setRepeatMode(AudioRepeat.off);
    _clearSleepTimer();
  }

  void _showPlaybackError([Object? error]) {
    final text = error.toString();
    final network = text.contains('UnknownHost') ||
        text.contains('SocketException') ||
        text.contains('Connection');
    showMessage(
      network
          ? S.noConnection
          : (contentType.value == AudioContentType.surah ? S.playSurahError : S.playHadithError),
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
