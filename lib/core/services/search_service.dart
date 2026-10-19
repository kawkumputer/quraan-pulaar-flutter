import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';
import '../utils/text_normalizer.dart';
import 'quran_service.dart';

/// Résultat de recherche : un nom de sourate ([verseIndex] == null) ou un verset.
class SearchResult {
  final SurahModel surah;
  final int? verseIndex;

  const SearchResult(this.surah, [this.verseIndex]);
}

class _IndexEntry {
  final int surahNumber;
  final int verseIndex;
  final String arabic;
  final String pulaar;

  const _IndexEntry(this.surahNumber, this.verseIndex, this.arabic, this.pulaar);
}

/// Index de recherche (texte normalisé), reconstruit hors du thread UI quand
/// les sourates changent.
class SearchService extends GetxService {
  static const int maxResults = 200;

  late final QuranService _quranService;
  List<_IndexEntry> _index = [];
  final isIndexing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _quranService = Get.find<QuranService>();
    ever(_quranService.surahsRx, (_) => _rebuild());
    _rebuild();
  }

  Future<void> _rebuild() async {
    final input = [
      for (final s in _quranService.surahs)
        for (var i = 0; i < s.verses.length; i++)
          [s.number, i, s.verses[i].arabic, s.verses[i].pulaar],
    ];
    if (input.isEmpty) return;
    isIndexing.value = true;
    try {
      _index = await compute(_buildIndex, input);
    } finally {
      isIndexing.value = false;
    }
  }

  static List<_IndexEntry> _buildIndex(List<List<Object>> input) => [
        for (final row in input)
          _IndexEntry(
            row[0] as int,
            row[1] as int,
            TextNormalizer.normalize(row[2] as String),
            TextNormalizer.normalize(row[3] as String),
          ),
      ];

  /// Noms de sourates d'abord, puis versets (au plus [maxResults]).
  List<SearchResult> search(String query) {
    final q = TextNormalizer.normalize(query.trim());
    if (q.isEmpty) return [];

    final results = <SearchResult>[];
    for (final s in _quranService.surahs) {
      if (s.number.toString() == q ||
          TextNormalizer.normalize(s.namePulaar).contains(q) ||
          TextNormalizer.normalize(s.nameArabic).contains(q)) {
        results.add(SearchResult(s));
      }
    }

    // Les versets suivent l'ordre d'affichage des sourates.
    final order = {
      for (var i = 0; i < _quranService.surahs.length; i++)
        _quranService.surahs[i].number: i,
    };
    final matches = _index
        .where((e) => e.arabic.contains(q) || e.pulaar.contains(q))
        .toList()
      ..sort((a, b) {
        final bySurah = (order[a.surahNumber] ?? 0).compareTo(order[b.surahNumber] ?? 0);
        return bySurah != 0 ? bySurah : a.verseIndex.compareTo(b.verseIndex);
      });

    for (final e in matches) {
      if (results.length >= maxResults) break;
      final surah = _quranService.byNumber(e.surahNumber);
      if (surah != null) results.add(SearchResult(surah, e.verseIndex));
    }
    return results;
  }
}
