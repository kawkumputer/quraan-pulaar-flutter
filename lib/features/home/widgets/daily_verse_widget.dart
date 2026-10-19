import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import '../../../core/utils/messenger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/bookmark_service.dart';
import '../../../core/services/quran_service.dart';
import '../../../core/utils/daily_verse.dart';
import '../../../core/routes/app_routes.dart';

class DailyVerseWidget extends StatefulWidget {
  const DailyVerseWidget({super.key});

  @override
  State<DailyVerseWidget> createState() => _DailyVerseWidgetState();
}

class _DailyVerseWidgetState extends State<DailyVerseWidget> {
  final _bookmarkService = Get.find<BookmarkService>();
  final _quranService = Get.find<QuranService>();

  /// Verset du jour parmi les sourates accessibles (recalculé quand elles changent).
  Map<String, dynamic> get _dailyVerseData {
    final daily =
        DailyVerse.forDate(DateTime.now(), _quranService.accessibleSurahs);
    if (daily == null) return {};
    return {
      'verse': daily.verse.arabic,
      'translation': daily.verse.pulaar,
      'surah': daily.surah.namePulaar,
      'verseNumber': daily.verse.number.toString(),
      'surahNumber': daily.surah.number,
      'shareText': daily.shareText,
    };
  }

  Future<void> _shareVerse(Map<String, dynamic> verse) async {
    final text = verse['shareText'] as String?;
    if (text == null) return;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  void _navigateToSurah(Map<String, dynamic> verse) {
    final surah = _quranService.byNumber(verse['surahNumber'] as int? ?? 0);
    if (surah != null) AppRoutes.openSurah(surah);
  }

  Future<void> _toggleBookmark(Map<String, dynamic> verse) async {
    final surahNumber = verse['surahNumber'] as int? ?? 0;
    if (surahNumber == 0) return;

    await _bookmarkService.toggleBookmark(surahNumber);

    final isBookmarked = _bookmarkService.isBookmarked(surahNumber);
    showMessage(isBookmarked
        ? 'Simoore nde ɓeydaama e maantaaɗi'
        : 'Simoore nde ittaama e maantaaɗi');
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Dépendances réactives : sourates chargées et état d'activation.
      _quranService.surahsRx.length;
      final v = _dailyVerseData;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Maande hannde ko',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.share, color: AppTheme.primaryColor),
                  onPressed: () => _shareVerse(v),
                ),
                Obx(() => IconButton(
                      icon: Icon(
                        _bookmarkService.isBookmarked(v['surahNumber'] ?? 0)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () => _toggleBookmark(v),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              if ((_quranService.isLoading && v.isEmpty)) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.dailyVerseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                );
              }

              if (v.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.dailyVerseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Roŋkii heɓde maande hannde',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _navigateToSurah(v),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.dailyVerseColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        v['verse'] ?? '',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 22,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        v['translation'] ?? '',
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${v['surah']} - maande ${v['verseNumber']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
