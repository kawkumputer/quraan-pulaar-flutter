import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/audio_controller.dart';
import '../../../core/widgets/audio_controls.dart';
import '../models/hadith.dart';

class HadithCard extends StatelessWidget {
  final Hadith hadith;

  const HadithCard({
    super.key,
    required this.hadith,
  });

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => audioController.togglePlay(hadith.id, hadith.url),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Obx(() {
                    final isCurrentHadith = audioController.currentlyPlayingId.value == hadith.id;
                    final isLoading = audioController.isLoading.value && isCurrentHadith;
                    final isPlaying = audioController.isPlaying.value && isCurrentHadith;

                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPlaying ? Colors.green : const Color(0xFF1F6E8C),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        isLoading
                            ? Icons.hourglass_empty
                            : isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  }),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hadith.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'حديث رقم ${hadith.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontFamily: 'Arabic',
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Obx(() {
            final isCurrentHadith = audioController.currentlyPlayingId.value == hadith.id;
            if (!isCurrentHadith) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AudioControls(
                audioPlayer: audioController.audioPlayer,
                isPlaying: audioController.isPlaying.value,
                onPlayPause: () => audioController.togglePlay(hadith.id, hadith.url),
                onStop: () => audioController.stopPlaying(),
              ),
            );
          }),
        ],
      ),
    );
  }
}
