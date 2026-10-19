import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/strings.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/services/quran_service.dart';
import '../../../core/services/reading_progress_service.dart';
import '../../../core/theme/app_theme.dart';

/// « Continuer la lecture » : rouvre la dernière sourate au dernier verset lu.
/// Masquée s'il n'y a rien à reprendre (ou si la sourate n'est plus accessible).
class RecentReadingCard extends StatelessWidget {
  const RecentReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final progressService = Get.find<ReadingProgressService>();
    final quranService = Get.find<QuranService>();

    return Obx(() {
      final progress = progressService.last.value;
      quranService.surahsRx.length; // dépendance : sourates chargées
      final surah =
          progress == null ? null : quranService.byNumber(progress.surahNumber);
      if (progress == null || surah == null || quranService.isLocked(surah)) {
        return const SizedBox.shrink();
      }
      final verseIndex = progress.verseIndex
          .clamp(0, surah.verses.isEmpty ? 0 : surah.verses.length - 1);
      final verseNumber =
          surah.verses.isEmpty ? 1 : surah.verses[verseIndex].number;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              child: const Icon(Icons.menu_book),
            ),
            title: const Text(S.continueReading,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${surah.namePulaar} · ${S.verse} $verseNumber'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppRoutes.openSurah(surah, verseIndex: verseIndex),
          ),
        ),
      );
    });
  }
}
