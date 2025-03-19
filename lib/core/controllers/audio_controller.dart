import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/surah_model.dart';
import '../services/quran_service.dart';
import '../../features/surah/surah_content_screen.dart';

// Track content type to handle different playback behaviors
enum AudioContentType { surah, hadith }

class AudioController extends GetxController {
  final audioPlayer = AudioPlayer();
  final QuranService _quranService = Get.find<QuranService>();
  int? _currentId;
  final RxInt currentlyPlayingId = RxInt(-1);
  final RxBool isLoading = RxBool(false);
  final RxBool isPlaying = RxBool(false);
  String? _artworkPath;
  bool _isInBackground = false;
  AudioContentType _currentContentType = AudioContentType.surah;

  AudioController() {
    _prepareArtwork();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    // Listen to player state changes
    audioPlayer.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        // Only handle auto-play for surahs
        if (_currentId != null && _currentContentType == AudioContentType.surah) {
          await navigateToNextSurah(autoPlay: true);
        } else {
          _resetState();
        }
      }
      isPlaying.value = state.playing;
    });

    // Listen to app lifecycle changes
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == AppLifecycleState.paused.toString()) {
        _isInBackground = true;
      } else if (msg == AppLifecycleState.resumed.toString()) {
        _isInBackground = false;
      }
      return null;
    });
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

  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
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
      if (_currentId != id) {
        await stopPlaying();
        _currentId = id;
        _currentContentType = contentType;

        // Set audio source with metadata for background playback
        final audioSource = AudioSource.uri(
          Uri.parse(url),
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
      }
      await audioPlayer.play();
      isPlaying.value = true;
      currentlyPlayingId.value = id;
    } catch (e) {
      print('Error playing audio: $e');
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
      _currentId = null;
      currentlyPlayingId.value = -1;
    } catch (e) {
      print('Error stopping playback: $e');
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
        if (!_isInBackground) {
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
        if (!_isInBackground) {
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
}
