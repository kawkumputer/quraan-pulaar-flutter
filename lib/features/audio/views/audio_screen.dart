import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import '../models/audio_surah.dart';

class AudioScreen extends GetView<AudioController> {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Quran'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (controller.errorMessage.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.errorMessage.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => controller.refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.surahs.isEmpty) {
                return const Center(
                  child: Text('No audio surahs available'),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.refresh(),
                child: ListView.builder(
                  itemCount: controller.surahs.length,
                  itemBuilder: (context, index) {
                    final surah = controller.surahs[index];
                    return _buildSurahTile(surah);
                  },
                ),
              );
            }),
          ),
          _buildNowPlayingBar(),
        ],
      ),
    );
  }

  Widget _buildSurahTile(AudioSurah surah) {
    return Obx(() {
      final isCurrentSurah = controller.currentSurah.value?.number == surah.number;
      final isPlaying = isCurrentSurah && controller.isPlaying.value;

      return ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(Get.context!).primaryColor,
          child: Text(
            surah.number.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(surah.name),
        subtitle: Text(surah.arabicName),
        trailing: IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 32,
            color: Theme.of(Get.context!).primaryColor,
          ),
          onPressed: () => controller.playSurah(surah),
        ),
      );
    });
  }

  Widget _buildNowPlayingBar() {
    return Obx(() {
      final currentSurah = controller.currentSurah.value;
      if (currentSurah == null) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSurah.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        currentSurah.arabicName,
                        style: TextStyle(
                          color: Theme.of(Get.context!).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    controller.isPlaying.value
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 48,
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                  onPressed: () {
                    if (controller.isPlaying.value) {
                      controller.pause();
                    } else {
                      controller.resume();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(Get.context!).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 4,
              ),
              child: Slider(
                value: controller.progress.value,
                onChanged: (value) {
                  final newPosition = Duration(
                    seconds: (value * controller.duration.value.inSeconds).round(),
                  );
                  controller.seek(newPosition);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(controller.position.value)),
                  Text(_formatDuration(controller.duration.value)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
