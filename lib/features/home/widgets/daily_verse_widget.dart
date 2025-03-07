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
import '../../../core/services/settings_service.dart';

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

    final settingsService = Get.find<SettingsService>();
    final isActivated = settingsService.isActivated;

    // Filter surahs based on activation status
    final availableSurahs = isActivated ? surahs : surahs.where((s) => s.number <= 4).toList();
    if (availableSurahs.isEmpty) return;

    // Use the current date as seed to ensure same verse throughout the day
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(seed);

    // First, randomly select a surah from available ones
    final surah = availableSurahs[random.nextInt(availableSurahs.length)];

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

- ${verse['surah']}, Maande ${verse['verseNumber']}

Ummoraade e Quraan Pulaar''';

    await Clipboard.setData(ClipboardData(text: shareText));
    Get.snackbar(
      'Naatii e ɗerewol',
      'Maande nde naatnaama e ɗerewol',
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
        'Juumre',
        'Roŋki maantaade maande nde e oo sahaa',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    await _bookmarkService.toggleBookmark(surahNumber);

    final isBookmarked = _bookmarkService.isBookmarked(surahNumber);
    Get.snackbar(
      isBookmarked ? 'Maantaama' : 'Maantol ittaama',
      isBookmarked ? 'Simoore nde ɓeydaama e maantaaɗi' : 'Simoore nde ittaama e maantaaɗi',
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
              Icon(Icons.wb_sunny, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Maande hande ko',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.share, color: AppTheme.primaryColor),
                onPressed: () => _shareVerse(_dailyVerse.value),
              ),
              Obx(() => IconButton(
                icon: Icon(
                  _bookmarkService.isBookmarked(_dailyVerse.value['surahNumber'] ?? 0)
                      ? Icons.bookmark
                      : Icons.bookmark_border,
                  color: AppTheme.primaryColor,
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

            if (_dailyVerse.value.isEmpty) {
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
              onTap: () => _navigateToSurah(_dailyVerse.value),
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
                      _dailyVerse.value['verse'] ?? '',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _dailyVerse.value['translation'] ?? '',
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
                                '${_dailyVerse.value['surah']} - maande ${_dailyVerse.value['verseNumber']}',
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
