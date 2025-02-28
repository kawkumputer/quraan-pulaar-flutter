import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class AudioController extends GetxController {
  final audioPlayer = AudioPlayer();  // Made public for AudioControls widget
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
      
      // Enable wakelock when playing, disable when stopped
      if (state.playing) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });
  }

  @override
  void onClose() {
    WakelockPlus.disable();  // Make sure to disable wakelock when disposing
    audioPlayer.dispose();
    super.onClose();
  }

  void _resetState() {
    currentlyPlayingId.value = -1;
    isPlaying.value = false;
    isLoading.value = false;
    WakelockPlus.disable();  // Disable wakelock when playback is reset
  }

  Future<void> togglePlay(int id, String url) async {
    try {
      // If tapping the currently playing hadith
      if (currentlyPlayingId.value == id) {
        if (isPlaying.value) {
          await audioPlayer.pause();
          isPlaying.value = false;
        } else {
          await audioPlayer.play();
          isPlaying.value = true;
        }
        return;
      }

      // If another hadith is playing, stop it first
      if (currentlyPlayingId.value != -1) {
        await stopPlaying();
      }

      // Start playing the new hadith
      isLoading.value = true;
      currentlyPlayingId.value = id;

      await audioPlayer.setUrl(url);
      await audioPlayer.play();
      isPlaying.value = true;

    } catch (e) {
      _resetState();
      Get.snackbar(
        'Error',
        'Error playing audio',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> stopPlaying() async {
    await audioPlayer.stop();
    _resetState();
  }
}
