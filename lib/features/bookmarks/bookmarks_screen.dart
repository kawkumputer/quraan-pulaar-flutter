import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/routes/app_routes.dart';

class BookmarksScreen extends StatelessWidget {
  BookmarksScreen({super.key});

  final _bookmarkService = Get.find<BookmarkService>();
  final _cacheService = Get.find<CacheService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
      ),
      body: Obx(() {
        final bookmarkedSurahs = _bookmarkService.bookmarkedSurahs;
        final allSurahs = _cacheService.getCachedSurahs();

        if (bookmarkedSurahs.isEmpty) {
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
                  'No bookmarks yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your bookmarked surahs will appear here',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookmarkedSurahs.length,
          itemBuilder: (context, index) {
            final surahNumber = bookmarkedSurahs[index];
            final surah = allSurahs.firstWhere(
              (s) => s.number == surahNumber,
              orElse: () => allSurahs.first,
            );

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
                  surah.namePulaar,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                subtitle: Text('${surah.versesCount} verses'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await _bookmarkService.toggleBookmark(surahNumber);
                    Get.snackbar(
                      'Bookmark Removed',
                      'Surah removed from bookmarks',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.grey,
                      colorText: Colors.white,
                    );
                  },
                ),
                onTap: () {
                  Get.toNamed(
                    AppRoutes.surah,
                    arguments: {
                      'surahNumber': surah.number,
                      'title': surah.namePulaar,
                      'audioUrl': surah.audioUrl,
                    },
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}
