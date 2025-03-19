import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../services/download_service.dart';
import '../../features/surah/surah_content_screen.dart';

// Track content type to handle different playback behaviors
enum AudioContentType { surah, hadith }

class AudioController extends GetxController {
  AudioPlayer? _audioPlayer;
  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }
  
  late final QuranService _quranService;
  late final DownloadService _downloadService;
  int? _currentId;
  final RxInt currentlyPlayingId = RxInt(-1);
  final RxBool isLoading = RxBool(false);
  final RxBool isPlaying = RxBool(false);
  String? _artworkPath;
  bool _isInBackground = false;
  AudioContentType _currentContentType = AudioContentType.surah;
  final RxBool isInitialized = RxBool(false);
  final RxMap<int, bool> downloadedSurahs = <int, bool>{}.obs;
  final RxMap<int, bool> downloadingSurahs = <int, bool>{}.obs;

  // Track app lifecycle state
  final Rx<AppLifecycleState> _lifecycleState = AppLifecycleState.resumed.obs;

  AudioController() {
    _prepareArtwork();
    _initializeServices();
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize audio player
    _setupAudioPlayer();
    
    // Listen to app lifecycle changes
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      switch (msg) {
        case "AppLifecycleState.paused":
          _lifecycleState.value = AppLifecycleState.paused;
          break;
        case "AppLifecycleState.resumed":
          _lifecycleState.value = AppLifecycleState.resumed;
          // Sync UI with current playback when app resumes
          _syncUIWithCurrentPlayback();
          break;
        case "AppLifecycleState.inactive":
          _lifecycleState.value = AppLifecycleState.inactive;
          break;
        case "AppLifecycleState.detached":
          _lifecycleState.value = AppLifecycleState.detached;
          break;
      }
      return null;
    });
  }

  @override
  void onClose() {
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.onClose();
  }

  void _initializeServices() {
    try {
      _quranService = Get.find<QuranService>();
      _downloadService = Get.find<DownloadService>();
      _loadDownloadedSurahs();
      isInitialized.value = true;
    } catch (e) {
      print('Error initializing AudioController services: $e');
      // Retry after a short delay
      Future.delayed(const Duration(milliseconds: 100), _initializeServices);
    }
  }

  Future<void> _loadDownloadedSurahs() async {
    try {
      for (var i = 1; i <= _quranService.surahs.length; i++) {
        if (_downloadService.isDownloaded(i)) {
          downloadedSurahs[i] = true;
        }
      }
    } catch (e) {
      print('Error loading downloaded surahs: $e');
    }
  }

  void _setupAudioPlayer() {
    if (!isInitialized.value) {
      Future.delayed(const Duration(milliseconds: 100), _setupAudioPlayer);
      return;
    }

    try {
      audioPlayer.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
      });

      audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          _onPlaybackComplete();
        }
      });
    } catch (e) {
      print('Error setting up audio player: $e');
    }
  }

  Future<void> _prepareArtwork() async {
    try {
      final bytes = await rootBundle.load('assets/icon/original.png');
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/app_icon.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());
      _artworkPath = file.path;
    } catch (e) {
      print('Error preparing artwork: $e');
    }
  }

  void _resetState() {
    currentlyPlayingId.value = -1;
    isPlaying.value = false;
    isLoading.value = false;
    _currentId = null;
  }

  Future<void> playUrl(int id, String url, {
    String? surahName,
    String? surahNameArabic,
    AudioContentType contentType = AudioContentType.surah,
  }) async {
    try {
      isLoading.value = true;
      _currentId = id;
      _currentContentType = contentType;

      // Check for offline file first
      String audioUrl = url;
      if (contentType == AudioContentType.surah) {
        final offlineUrl = await _downloadService.getOfflineUrl(id);
        if (offlineUrl != null) {
          audioUrl = offlineUrl;
          print('Playing from offline URL: $audioUrl'); // Debug log
        } else if (!_downloadService.isDownloading(id)) {
          // Start downloading in background if not already downloading
          downloadSurah(id); // Don't await, let it download in background
        }
      }

      // Set audio source with metadata for background playback
      final Uri uri;
      if (audioUrl.startsWith('http')) {
        // Online URL (hadiths or online surahs)
        uri = Uri.parse(audioUrl);
      } else {
        // Local file (downloaded surahs)
        if (Platform.isIOS) {
          // iOS needs file:// scheme for local files
          uri = Uri.parse('file://$audioUrl');
        } else {
          // Android can use direct file path
          uri = Uri.file(audioUrl);
        }
      }

      final audioSource = AudioSource.uri(
        uri,
        tag: MediaItem(
          id: id.toString(),
          title: contentType == AudioContentType.surah
            ? (surahName ?? 'Simoore $id')
            : 'Hadiis $id',
          artist: 'Quraan Pulaar',
          album: contentType == AudioContentType.surah ? 'Quraan Pulaar' : 'Hadiisaaji',
          displayTitle: contentType == AudioContentType.surah ? '$surahName - $surahNameArabic' : null,
          artUri: _artworkPath != null ? Uri.file(_artworkPath!) : null,
        ),
      );

      await audioPlayer.setAudioSource(audioSource);
      await audioPlayer.play();
      isPlaying.value = true;
      currentlyPlayingId.value = id;
    } catch (e) {
      print('Error playing audio: $e');
      isPlaying.value = false;
      currentlyPlayingId.value = -1;
      Get.snackbar(
        'Juumre',
        'Roŋki aawtaade ${_currentContentType == AudioContentType.surah ? "simoore" : "hadiisa"} nde',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void togglePlay(int id, String url, {
    String? surahName,
    String? surahNameArabic,
    AudioContentType contentType = AudioContentType.surah,
  }) {
    if (currentlyPlayingId.value == id && isPlaying.value) {
      audioPlayer.pause();
      isPlaying.value = false;
    } else {
      playUrl(
        id,
        url,
        surahName: surahName,
        surahNameArabic: surahNameArabic,
        contentType: contentType,
      );
    }
  }

  Future<void> pause() async {
    try {
      await audioPlayer.pause();
      isPlaying.value = false;
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }

  Future<void> stopPlaying() async {
    try {
      await audioPlayer.stop();
      isPlaying.value = false;
      currentlyPlayingId.value = -1;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  void _onPlaybackComplete() async {
    if (_currentContentType == AudioContentType.surah) {
      // Auto-play next surah (in reverse order since we're starting from An-Naas)
      final nextSurahNumber = (_currentId ?? 0) - 1;
      if (nextSurahNumber > 0) {  // Stop at Al-Fatiha (1)
        final nextSurah = _quranService.surahs.firstWhere(
          (s) => s.number == nextSurahNumber,
          orElse: () => _quranService.surahs.first,
        );
        
        // Check if app is in foreground or background
        final isBackground = _lifecycleState.value == AppLifecycleState.paused;
        
        if (isBackground) {
          // In background, just play next surah without navigation
          await playUrl(
            nextSurah.number,
            nextSurah.audioUrl,
            surahName: nextSurah.namePulaar,
            surahNameArabic: nextSurah.nameArabic,
          );
        } else {
          // In foreground, navigate and play
          await Get.offNamed('/surah/${nextSurah.number}', arguments: nextSurah);
          await playUrl(
            nextSurah.number,
            nextSurah.audioUrl,
            surahName: nextSurah.namePulaar,
            surahNameArabic: nextSurah.nameArabic,
          );
        }
      }
    }
  }

  Future<void> navigateToNextSurah({bool autoPlay = true}) async {
    if (_currentId != null) {
      final currentSurah = _quranService.surahs.firstWhere(
        (s) => s.number == _currentId,
        orElse: () => _quranService.surahs.first,
      );
      final currentIndex = _quranService.surahs.indexOf(currentSurah);

      if (currentIndex < _quranService.surahs.length - 1) {
        final nextSurah = _quranService.surahs[currentIndex + 1];

        // Update the current surah in QuranService
        _quranService.setCurrentSurah(nextSurah);

        if (autoPlay) {
          await playUrl(
            nextSurah.number,
            nextSurah.audioUrl,
            surahName: nextSurah.namePulaar,
            surahNameArabic: nextSurah.nameArabic,
          );
        }

        // If not in background, navigate to the next surah screen
        if (_lifecycleState.value != AppLifecycleState.paused) {
          Get.off(
            () => SurahContentScreen(surah: nextSurah),
            transition: Transition.rightToLeft,
            preventDuplicates: false,
            arguments: autoPlay ? {'autoPlay': true} : null,
          );
        }
      }
    }
  }

  Future<void> navigateToPreviousSurah({bool autoPlay = true}) async {
    if (_currentId != null) {
      final currentSurah = _quranService.surahs.firstWhere(
        (s) => s.number == _currentId,
        orElse: () => _quranService.surahs.first,
      );
      final currentIndex = _quranService.surahs.indexOf(currentSurah);

      if (currentIndex > 0) {
        final previousSurah = _quranService.surahs[currentIndex - 1];

        // Update the current surah in QuranService
        _quranService.setCurrentSurah(previousSurah);

        if (autoPlay) {
          await playUrl(
            previousSurah.number,
            previousSurah.audioUrl,
            surahName: previousSurah.namePulaar,
            surahNameArabic: previousSurah.nameArabic,
          );
        }

        // If not in background, navigate to the previous surah screen
        if (_lifecycleState.value != AppLifecycleState.paused) {
          Get.off(
            () => SurahContentScreen(surah: previousSurah),
            transition: Transition.leftToRight,
            preventDuplicates: false,
            arguments: autoPlay ? {'autoPlay': true} : null,
          );
        }
      }
    }
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
    try {
      final surah = _quranService.surahs.firstWhere((s) => s.number == surahNumber);
      return await _downloadService.downloadSurah(surah);
    } catch (e) {
      print('Error downloading surah: $e');
      return false;
    }
  }

  Future<void> deleteSurah(int surahNumber) async {
    try {
      await _downloadService.deleteSurah(surahNumber);
      downloadedSurahs[surahNumber] = false;
    } catch (e) {
      print('Error deleting surah: $e');
    }
  }

  // Sync UI with current playback state
  void _syncUIWithCurrentPlayback() async {
    if (_currentContentType == AudioContentType.surah && _currentId != null) {
      final currentSurah = _quranService.surahs.firstWhere(
        (s) => s.number == _currentId,
        orElse: () => _quranService.surahs.first,
      );
      
      // Only navigate if we're on a different surah screen
      if (Get.currentRoute != '/surah/${currentSurah.number}') {
        await Get.offNamed('/surah/${currentSurah.number}', arguments: currentSurah);
      }
    }
  }

  Future<void> playNext() async {
    if (_currentContentType == AudioContentType.surah && _currentId != null) {
      final nextSurahNumber = _currentId! - 1;  // Play in reverse order
      if (nextSurahNumber > 0) {  // Stop at Al-Fatiha (1)
        final nextSurah = _quranService.surahs.firstWhere(
          (s) => s.number == nextSurahNumber,
          orElse: () => _quranService.surahs.first,
        );

        // If not in background, navigate to the next surah screen
        if (_lifecycleState.value != AppLifecycleState.paused) {
          Get.off(
            () => SurahContentScreen(surah: nextSurah),
            transition: Transition.rightToLeft,
          );
        }

        // Play the next surah
        await playUrl(
          nextSurah.number,
          nextSurah.audioUrl,
          surahName: nextSurah.namePulaar,
          surahNameArabic: nextSurah.nameArabic,
        );
      }
    }
  }

  Future<void> playPrevious() async {
    if (_currentContentType == AudioContentType.surah && _currentId != null) {
      final previousSurahNumber = _currentId! + 1;  // Play in reverse order
      if (previousSurahNumber <= _quranService.surahs.length) {  // Stop at An-Naas (114)
        final previousSurah = _quranService.surahs.firstWhere(
          (s) => s.number == previousSurahNumber,
          orElse: () => _quranService.surahs.last,
        );

        // If not in background, navigate to the previous surah screen
        if (_lifecycleState.value != AppLifecycleState.paused) {
          Get.off(
            () => SurahContentScreen(surah: previousSurah),
            transition: Transition.leftToRight,
          );
        }

        // Play the previous surah
        await playUrl(
          previousSurah.number,
          previousSurah.audioUrl,
          surahName: previousSurah.namePulaar,
          surahNameArabic: previousSurah.nameArabic,
        );
      }
    }
  }
}
