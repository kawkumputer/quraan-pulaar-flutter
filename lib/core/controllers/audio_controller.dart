import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/surah_model.dart';

class AudioController extends GetxController {
  final audioPlayer = AudioPlayer();  // Made public for AudioControls widget
  int? _currentId;
  final RxInt currentlyPlayingId = RxInt(-1);
  final RxBool isLoading = RxBool(false);
  final RxBool isPlaying = RxBool(false);
  String? _artworkPath;

  AudioController() {
    // Listen to player state changes
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _resetState();
      }
      isPlaying.value = state.playing;
    });
    _prepareArtwork();
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
  }

  Future<void> playUrl(int id, String url, {String? surahName, String? surahNameArabic}) async {
    try {
      isLoading.value = true;
      if (_currentId != id) {
        await stopPlaying();
        _currentId = id;
        
        // Set audio source with metadata for background playback
        final audioSource = AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: id.toString(),
            title: surahName ?? 'Simoore $id',
            artist: 'Quraan Pulaar',
            album: 'Quraan Pulaar',
            displayTitle: surahNameArabic,
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
        'Roŋki aawtaade simoore nde',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> togglePlay(int id, String url, {String? surahName, String? surahNameArabic}) async {
    try {
      if (audioPlayer.playing) {
        await pause();
      } else {
        await playUrl(id, url, surahName: surahName, surahNameArabic: surahNameArabic);
      }
    } catch (e) {
      print('Error toggling play: $e');
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
}
