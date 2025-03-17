import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class AudioController extends GetxController {
  final audioPlayer = AudioPlayer();  // Made public for AudioControls widget
  int? _currentId;
  final RxInt currentlyPlayingId = RxInt(-1);
  final RxBool isLoading = RxBool(false);
  final RxBool isPlaying = RxBool(false);

  AudioController() {
    // Listen to player state changes
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _resetState();
      }
      isPlaying.value = state.playing;
    });
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

  Future<void> playUrl(int id, String url) async {
    try {
      isLoading.value = true;
      if (_currentId != id) {
        await stopPlaying();
        _currentId = id;
        await audioPlayer.setUrl(url);
      }
      await audioPlayer.play();
      isPlaying.value = true;
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

  Future<void> togglePlay(int id, String url) async {
    try {
      if (audioPlayer.playing) {
        await pause();
      } else {
        await playUrl(id, url);
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
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }
}
