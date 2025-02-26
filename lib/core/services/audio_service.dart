import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class AudioService extends GetxService {
  final _audioPlayer = AudioPlayer();
  final _isPlaying = false.obs;
  final _currentSurahNumber = 0.obs;
  final _progress = 0.0.obs;
  final _duration = Duration.zero.obs;
  final _position = Duration.zero.obs;

  bool get isPlaying => _isPlaying.value;
  int get currentSurahNumber => _currentSurahNumber.value;
  double get progress => _progress.value;
  Duration get duration => _duration.value;
  Duration get position => _position.value;

  @override
  void onInit() {
    super.onInit();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying.value = state.playing;
    });

    _audioPlayer.durationStream.listen((d) {
      _duration.value = d ?? Duration.zero;
    });

    _audioPlayer.positionStream.listen((p) {
      _position.value = p;
      if (_duration.value != Duration.zero) {
        _progress.value = p.inMilliseconds / _duration.value.inMilliseconds;
      }
    });
  }

  Future<void> playSurah(String url, int surahNumber) async {
    if (currentSurahNumber == surahNumber && isPlaying) {
      await pause();
      return;
    }

    try {
      _currentSurahNumber.value = surahNumber;
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not play audio: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _currentSurahNumber.value = 0;
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
