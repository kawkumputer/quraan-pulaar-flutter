import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/messenger.dart';
import '../../core/constants/strings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/quran_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/routes/app_routes.dart';

class BookmarksScreen extends GetView<BookmarkService> {
  BookmarksScreen({super.key});

  final _quranService = Get.find<QuranService>();
  final _settingsService = Get.find<SettingsService>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(S.bookmarksTitle),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.back();
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Obx(() {
                final availableBookmarks = controller.bookmarkedSurahs;
                final verseBookmarks = controller.verseBookmarks;
                _quranService
                    .surahsRx.length; // recharge quand les sourates changent

                if (availableBookmarks.isEmpty && verseBookmarks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          S.noBookmarks,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          S.noBookmarksHint,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                // Versets en favori d'abord (avec titre de section), puis les sourates.
                final verseCount =
                    verseBookmarks.isEmpty ? 0 : verseBookmarks.length + 1;
                final surahHeader = availableBookmarks.isEmpty ? 0 : 1;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      verseCount + surahHeader + availableBookmarks.length,
                  itemBuilder: (context, rawIndex) {
                    if (verseCount > 0 && rawIndex == 0) {
                      return _SectionTitle(S.bookmarkedVerses);
                    }
                    if (rawIndex < verseCount) {
                      return _VerseBookmarkTile(
                          bookmark: verseBookmarks[rawIndex - 1]);
                    }
                    if (rawIndex == verseCount) {
                      return _SectionTitle(S.bookmarkedSurahs);
                    }
                    final index = rawIndex - verseCount - surahHeader;
                    final surahNumber = availableBookmarks[index];
                    // Sourate absente (pas encore chargée, ou verrouillée après désactivation)
                    final surah = _quranService.byNumber(surahNumber);
                    final locked =
                        surah == null || _quranService.isLocked(surah);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              surahNumber.toString(),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          surah != null ? S.surahName(surah) : S.surahN(surahNumber),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        subtitle: locked
                            ? const Icon(Icons.lock_outline, size: 16)
                            : Text(S.versesCount(surah.verses.length)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await controller.toggleBookmark(surahNumber);
                            showMessage(S.surahUnbookmarked);
                          },
                        ),
                        onTap: locked
                            ? () => Get.toNamed(AppRoutes.activation)
                            : () => AppRoutes.openSurah(surah),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _VerseBookmarkTile extends StatelessWidget {
  final VerseBookmark bookmark;

  const _VerseBookmarkTile({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final quranService = Get.find<QuranService>();
    final bookmarks = Get.find<BookmarkService>();
    final surah = quranService.byNumber(bookmark.surahNumber);
    final available = surah != null &&
        !quranService.isLocked(surah) &&
        bookmark.verseIndex < surah.verses.length;
    final verse = available ? surah.verses[bookmark.verseIndex] : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          verse == null
              ? S.surahN(bookmark.surahNumber)
              : S.verseRef(surah!, verse.number),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: verse == null
            ? const Icon(Icons.lock_outline, size: 16)
            : Text(verse.pulaar,
                maxLines: 2, overflow: TextOverflow.ellipsis, textDirection: TextDirection.ltr),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => bookmarks.toggleVerseBookmark(
              bookmark.surahNumber, bookmark.verseIndex),
        ),
        onTap: verse == null
            ? () => Get.toNamed(AppRoutes.activation)
            : () =>
                AppRoutes.openSurah(surah!, verseIndex: bookmark.verseIndex),
      ),
    );
  }
}
