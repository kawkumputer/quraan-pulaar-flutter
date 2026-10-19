import 'package:flutter_test/flutter_test.dart';
import 'package:quraan_pulaar/core/models/surah_model.dart';
import 'package:quraan_pulaar/core/models/verse_model.dart';
import 'package:quraan_pulaar/core/utils/daily_verse.dart';
import 'package:quraan_pulaar/core/utils/version.dart';

SurahModel _surah(int number, int verses) => SurahModel(
      number: number,
      nameArabic: 'S$number',
      namePulaar: 'Simoore $number',
      verses: [
        for (var i = 1; i <= verses; i++)
          VerseModel(number: i, arabic: 'a$i', pulaar: 'p$i'),
      ],
    );

void main() {
  group('compareVersions', () {
    test('ordre numérique, pas lexical', () {
      expect(compareVersions('2.10.0', '2.9.1'), greaterThan(0));
      expect(compareVersions('2.9.1', '2.10.0'), lessThan(0));
    });

    test('égalité et suffixes ignorés', () {
      expect(compareVersions('2.11.0', '2.11.0+32'), 0);
      expect(compareVersions('2.11', '2.11.0'), 0);
      expect(compareVersions('3.0.0-beta', '3.0.0'), 0);
    });
  });

  group('DailyVerse.forDate', () {
    final surahs = [_surah(114, 6), _surah(1, 7), _surah(2, 0), _surah(112, 4)];
    final date = DateTime(2026, 10, 19);

    test("même verset pour une date, quel que soit l'ordre des sourates", () {
      final a = DailyVerse.forDate(date, surahs)!;
      final b = DailyVerse.forDate(date, surahs.reversed.toList())!;
      expect(a.surah.number, b.surah.number);
      expect(a.verse.number, b.verse.number);
    });

    test('ignore les sourates sans versets', () {
      for (var d = 0; d < 60; d++) {
        final daily = DailyVerse.forDate(date.add(Duration(days: d)), surahs)!;
        expect(daily.surah.number, isNot(2));
      }
    });

    test('null sans sourate', () {
      expect(DailyVerse.forDate(date, []), isNull);
    });
  });
}
