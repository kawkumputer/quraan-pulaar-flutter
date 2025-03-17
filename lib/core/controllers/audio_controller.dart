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

  Future<void> togglePlay(int id, String url) async {
    try {
      isLoading.value = true;
      
      // Check if we're playing a different audio
      if (_currentId != id) {
        await stopPlaying();
        _currentId = id;
        await audioPlayer.setUrl(url);
      }

      if (isPlaying.value) {
        await audioPlayer.pause();
        isPlaying.value = false;
      } else {
        await audioPlayer.play();
        isPlaying.value = true;
      }
    } catch (e) {
      print('Error toggling play: $e');
    } finally {
      isLoading.value = false;
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
