import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/audio_controller.dart';
import '../../../core/widgets/audio_controls.dart';
import '../../../core/widgets/audio_options_sheet.dart';
import '../../../core/theme/app_theme.dart';
import '../models/hadith.dart';

class HadithCard extends StatelessWidget {
  final Hadith hadith;

  /// Hadiths accessibles (playlist) et position de celui-ci dans la liste.
  final List<HadithItem> playlist;
  final int playlistIndex;

  const HadithCard({
    super.key,
    required this.hadith,
    required this.playlist,
    required this.playlistIndex,
  });

  void _toggle() => Get.find<AudioController>().toggleHadith(playlist, playlistIndex);

  @override
  Widget build(BuildContext context) {
    final audioController = Get.find<AudioController>();
    bool isCurrent() =>
        audioController.contentType.value == AudioContentType.hadith &&
        audioController.currentlyPlayingId.value == hadith.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Obx(() {
                    final current = isCurrent();
                    final isLoading = audioController.isLoading.value && current;
                    final isPlaying = audioController.isPlaying.value && current;

                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPlaying
                            ? AppTheme.primaryColor.withValues(alpha: 0.8)
                            : AppTheme.primaryColor,
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
                            fontFamily: 'Amiri',
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
            if (!isCurrent()) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AudioControls(
                audioPlayer: audioController.audioPlayer,
                onPlayPressed: _toggle,
                onPausePressed: _toggle,
                onStopPressed: audioController.stopPlaying,
                onPreviousPressed:
                    audioController.hasPrevious ? audioController.skipPrevious : null,
                onNextPressed: audioController.hasNext ? audioController.skipNext : null,
                onMorePressed: AudioOptionsSheet.show,
              ),
            );
          }),
        ],
      ),
    );
  }
}
