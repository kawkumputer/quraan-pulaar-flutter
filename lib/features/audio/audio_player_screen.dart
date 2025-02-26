import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';

class AudioPlayerScreen extends StatelessWidget {
  final String audioUrl;
  final String title;
  final String subtitle;

  const AudioPlayerScreen({
    super.key,
    required this.audioUrl,
    required this.title,
    required this.subtitle,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final _audioService = Get.find<QuranAudioService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _audioService.stop();
            Get.back();
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.primaryColor.withOpacity(0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.music_note,
                size: 120,
                color: Colors.white70,
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Obx(() {
                final position = _audioService.position;
                final duration = _audioService.duration;
                
                return Column(
                  children: [
                    Slider(
                      value: _audioService.progress,
                      onChanged: (value) {
                        if (duration != Duration.zero) {
                          final newPosition = value * duration.inMilliseconds;
                          _audioService.seekTo(Duration(milliseconds: newPosition.round()));
                        }
                      },
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(color: Colors.white70),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 32),
              Obx(() {
                if (_audioService.isLoading) {
                  return const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _audioService.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.white,
                      ),
                      onPressed: () => _audioService.playAudio(audioUrl),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
