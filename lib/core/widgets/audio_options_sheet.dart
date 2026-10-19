import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/strings.dart';
import '../controllers/audio_controller.dart';

/// Réglages de lecture : vitesse, répétition, minuterie de veille.
class AudioOptionsSheet extends StatelessWidget {
  const AudioOptionsSheet({super.key});

  static Future<void> show() {
    return Get.bottomSheet(
      const AudioOptionsSheet(),
      backgroundColor: Get.theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    );
  }

  static const _speeds = [0.75, 1.0, 1.25, 1.5];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<AudioController>();
    final title = Theme.of(context).textTheme.titleSmall;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Obx(() {
          final isSurah = c.contentType.value == AudioContentType.surah && c.currentSurah.value != null;
          final sleepAt = c.sleepAt.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.speed, style: title),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in _speeds)
                    ChoiceChip(
                      label: Text('${s}x'),
                      selected: c.speed.value == s,
                      onSelected: (_) => c.setSpeed(s),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(S.repeat, style: title),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(S.repeatOff),
                    selected: c.repeatMode.value == AudioRepeat.off,
                    onSelected: (_) => c.setRepeatMode(AudioRepeat.off),
                  ),
                  ChoiceChip(
                    label: Text(S.repeatItem),
                    selected: c.repeatMode.value == AudioRepeat.surah,
                    onSelected: (_) => c.setRepeatMode(AudioRepeat.surah),
                  ),
                  if (isSurah)
                    ChoiceChip(
                      label: Text(S.repeatVerse),
                      selected: c.repeatMode.value == AudioRepeat.verse,
                      onSelected: (_) => c.setRepeatMode(AudioRepeat.verse),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(S.sleepTimer, style: title),
              Wrap(
                spacing: 8,
                children: [
                  for (final minutes in [15, 30, 60])
                    ActionChip(
                      label: Text('$minutes min'),
                      onPressed: () => c.setSleepTimer(Duration(minutes: minutes)),
                    ),
                  ChoiceChip(
                    label: Text(S.sleepEndOfItem),
                    selected: c.sleepAtEndOfItem.value,
                    onSelected: (_) => c.setSleepTimer(null),
                  ),
                  if (sleepAt != null || c.sleepAtEndOfItem.value)
                    ActionChip(
                      avatar: const Icon(Icons.close, size: 16),
                      label: Text(S.cancel),
                      onPressed: c.cancelSleepTimer,
                    ),
                ],
              ),
              if (sleepAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${S.sleepAt} ${TimeOfDay.fromDateTime(sleepAt).format(context)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
            ],
          );
        }),
      ),
    );
  }
}
