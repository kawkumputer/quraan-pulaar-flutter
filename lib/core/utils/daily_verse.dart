import 'dart:math';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../constants/strings.dart';

/// Verset du jour : le même pour une date donnée, quel que soit l'ordre d'affichage.
/// Utilisé par l'accueil et par le rappel quotidien.
class DailyVerse {
  final SurahModel surah;
  final VerseModel verse;

  const DailyVerse(this.surah, this.verse);

  static DailyVerse? forDate(DateTime date, List<SurahModel> surahs) {
    final candidates = surahs.where((s) => s.verses.isNotEmpty).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    if (candidates.isEmpty) return null;

    final random = Random(date.year * 10000 + date.month * 100 + date.day);
    final surah = candidates[random.nextInt(candidates.length)];
    final verse = surah.verses[random.nextInt(surah.verses.length)];
    return DailyVerse(surah, verse);
  }

  String get reference => S.verseRef(surah, verse.number);

  String get shareText => '''${verse.arabic}

${verse.pulaar}

- $reference

${S.source}''';
}
