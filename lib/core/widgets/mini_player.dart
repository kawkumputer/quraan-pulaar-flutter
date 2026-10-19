import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'audio_options_sheet.dart';
import '../controllers/audio_controller.dart';
import '../routes/app_routes.dart';
import '../routes/route_observer.dart';
import '../constants/strings.dart';

/// Barre de lecture affichée en bas de l'app quand une sourate joue ailleurs
/// que sur son propre écran. Un appui rouvre la sourate.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AudioController>();

    return Obx(() {
      final surah = controller.currentSurah.value;
      final isHadith = controller.contentType.value == AudioContentType.hadith &&
          controller.currentlyPlayingId.value >= 0;
      final route = AppRouteObserver.currentRoute.value;
      final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
      final hidden = (surah == null && !isHadith) ||
          (surah != null && route == AppRoutes.surahPath(surah.number)) ||
          (isHadith && route == AppRoutes.hadith) ||
          route == AppRoutes.splash ||
          keyboardOpen;
      if (hidden) return const SizedBox.shrink();
      final title = isHadith
          ? S.hadithN(controller.currentlyPlayingId.value)
          : S.surahName(surah!);
      final subtitle = isHadith ? S.hadithsTitle : surah!.nameArabic;

      final theme = Theme.of(context);
      return Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: () => isHadith ? Get.toNamed(AppRoutes.hadith) : AppRoutes.openSurah(surah!),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: controller.audioPlayer.positionStream,
                  builder: (context, snapshot) {
                    final total = controller.audioPlayer.duration?.inMilliseconds ?? 0;
                    final pos = snapshot.data?.inMilliseconds ?? 0;
                    return LinearProgressIndicator(
                      value: total > 0 ? (pos / total).clamp(0.0, 1.0) : null,
                      minHeight: 2,
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              subtitle,
                              maxLines: 1,
                              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Amiri'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(controller.isPlaying.value ? Icons.pause : Icons.play_arrow),
                        onPressed: () => controller.isPlaying.value
                            ? controller.pause()
                            : controller.audioPlayer.play(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        onPressed: AudioOptionsSheet.show,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: controller.stopPlaying,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
