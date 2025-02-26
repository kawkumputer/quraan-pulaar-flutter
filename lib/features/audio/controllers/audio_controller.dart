import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_surah.dart';
import '../../../core/services/audio_firestore_service.dart';

class AudioController extends GetxController {
  final _audioPlayer = AudioPlayer();
  final currentSurah = Rx<AudioSurah?>(null);
  final isPlaying = false.obs;
  final progress = 0.0.obs;
  final duration = Duration.zero.obs;
  final position = Duration.zero.obs;
  final surahs = <AudioSurah>[].obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  final AudioFirestoreService _firestoreService = Get.find<AudioFirestoreService>();

  @override
  void onInit() {
    super.onInit();
    _loadSurahs();
    _setupAudioPlayerListeners();
  }

  Future<void> _loadSurahs() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final loadedSurahs = await _firestoreService.loadAudioSurahs();
      surahs.value = loadedSurahs;
      
      if (surahs.isEmpty) {
        errorMessage.value = 'No audio surahs found';
      }
    } catch (e) {
      errorMessage.value = 'Error loading audio surahs';
      print('Error in _loadSurahs: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      isPlaying.value = state.playing;
    });

    _audioPlayer.positionStream.listen((pos) {
      position.value = pos;
      if (duration.value.inSeconds > 0) {
        progress.value = pos.inSeconds / duration.value.inSeconds;
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      duration.value = dur ?? Duration.zero;
    });
  }

  Future<void> playSurah(AudioSurah surah) async {
    try {
      if (currentSurah.value?.number == surah.number) {
        if (isPlaying.value) {
          await pause();
        } else {
          await resume();
        }
        return;
      }

      currentSurah.value = surah;
      await _audioPlayer.setUrl(surah.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to play audio: ${e.toString()}',
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

  Future<void> refresh() async {
    await _loadSurahs();
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    super.onClose();
  }
}
