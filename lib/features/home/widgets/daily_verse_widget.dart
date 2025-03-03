import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:math';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/bookmark_service.dart';
import '../../../core/services/firebase_service.dart';
import '../../../features/surah/models/surah.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/models/surah_model.dart';

class DailyVerseWidget extends StatefulWidget {
  const DailyVerseWidget({super.key});

  @override
  State<DailyVerseWidget> createState() => _DailyVerseWidgetState();
}

class _DailyVerseWidgetState extends State<DailyVerseWidget> {
  final _bookmarkService = Get.find<BookmarkService>();
  final _cacheService = Get.find<CacheService>();
  final _firebaseService = Get.find<FirebaseService>();
  final _dailyVerse = Rx<Map<String, dynamic>>({});
  final _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _loadVerseData();
  }

  Future<void> _loadVerseData() async {
    _isLoading.value = true;
    try {
      var surahs = _cacheService.getCachedSurahs();
      if (surahs.isEmpty) {
        // If cache is empty, try to load from Firebase
        final allSurahs = await _firebaseService.getAllSurahs();
        if (allSurahs != null && allSurahs.isNotEmpty) {
          await _cacheService.cacheSurahs(allSurahs);
          surahs = allSurahs;
        }
      }

      if (surahs.isNotEmpty) {
        _getDailyVerse(surahs);
      }
    } finally {
      _isLoading.value = false;
    }
  }

  void _getDailyVerse(List<Surah> surahs) {
    if (_dailyVerse.value.isNotEmpty) {
      return;
    }

    // Use the current date as seed to ensure same verse throughout the day
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);

    // First, randomly select a surah
    final surah = surahs[random.nextInt(surahs.length)];

    // Then, randomly select a verse from that surah
    if (surah.verses.isEmpty) {
      return;
    }

    final verse = surah.verses[random.nextInt(surah.verses.length)];

    final verseData = {
      'verse': verse.arabic,
      'translation': verse.pulaar,
      'surah': surah.namePulaar,
      'verseNumber': verse.number.toString(),
      'surahNumber': surah.number,
      'audioUrl': surah.audioUrl,
    };

    _dailyVerse.value = verseData;
  }

  Future<void> _shareVerse(Map<String, dynamic> verse) async {
    final shareText = '''${verse['verse']}

${verse['translation']}

- ${verse['surah']}, Verse ${verse['verseNumber']}

Shared from Quraan Pulaar App''';

    await Clipboard.setData(ClipboardData(text: shareText));
    Get.snackbar(
      'Copied to Clipboard',
      'Verse has been copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _navigateToSurah(Map<String, dynamic> verse) {
    if (verse['surahNumber'] == null) return;

    final surah = _cacheService.getCachedSurahs().firstWhere(
      (s) => s.number == verse['surahNumber'],
      orElse: () => Surah(
        number: 0,
        juzNumber: 0,
        nameArabic: '',
        namePulaar: '',
        versesCount: 0,
        audioUrl: '',
        verses: [],
      ),
    );

    if (surah.number == 0) return;

    Get.toNamed(
      AppRoutes.surah,
      arguments: SurahModel.fromFirebase(surah),
    );
  }

  Future<void> _toggleBookmark(Map<String, dynamic> verse) async {
    final surahNumber = verse['surahNumber'] as int;
    if (surahNumber == 0) {
      Get.snackbar(
        'Error',
        'Cannot bookmark this verse at the moment',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await _bookmarkService.toggleBookmark(surahNumber);

    final isBookmarked = _bookmarkService.isBookmarked(surahNumber);
    Get.snackbar(
      isBookmarked ? 'Bookmarked' : 'Bookmark Removed',
      isBookmarked ? 'Surah added to bookmarks' : 'Surah removed from bookmarks',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isBookmarked ? Colors.green : Colors.grey,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny),
              const SizedBox(width: 8),
              const Text(
                'Maande hande ko',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareVerse(_dailyVerse.value),
              ),
              Obx(() => IconButton(
                icon: Icon(
                  _bookmarkService.isBookmarked(_dailyVerse.value['surahNumber'] ?? 0)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                ),
                onPressed: () => _toggleBookmark(_dailyVerse.value),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (_isLoading.value) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F6E8C),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading daily verse...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final dailyVerse = _dailyVerse.value;
            if (dailyVerse.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F6E8C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Could not load verse. Please try again later.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return InkWell(
              onTap: () => _navigateToSurah(dailyVerse),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F6E8C),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      dailyVerse['verse']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dailyVerse['translation']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                '${dailyVerse['surah']} - Verse ${dailyVerse['verseNumber']}',
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
  }
}
