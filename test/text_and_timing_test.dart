import 'package:flutter_test/flutter_test.dart';
import 'package:quraan_pulaar/core/models/surah_model.dart';
import 'package:quraan_pulaar/core/models/verse_model.dart';
import 'package:quraan_pulaar/core/utils/text_normalizer.dart';
import 'package:quraan_pulaar/core/utils/verse_timing.dart';

void main() {
  group('TextNormalizer', () {
    test('Pulaar : lettres spéciales et casse', () {
      expect(TextNormalizer.normalize('Ɓe ɗaɓɓi ŋari ƴeew'), 'be dabbi nari yeew');
    });

    test('arabe : diacritiques ignorés, alef unifié', () {
      expect(TextNormalizer.normalize('الرَّحْمَٰنِ'), TextNormalizer.normalize('الرحمن'));
      expect(TextNormalizer.normalize('أَحَد'), 'احد');
    });

    test('findInOriginal renvoie la plage dans le texte d\'origine', () {
      const original = 'Jom ɓe ɗoo';
      final range = TextNormalizer.findInOriginal(original, TextNormalizer.normalize('be'))!;
      expect(original.substring(range.$1, range.$2), 'ɓe');
    });

    test('findInOriginal inclut les diacritiques de la dernière lettre', () {
      const original = 'بِسْمِ اللَّهِ';
      final range = TextNormalizer.findInOriginal(original, TextNormalizer.normalize('بسم'))!;
      expect(original.substring(range.$1, range.$2), 'بِسْمِ');
    });
  });

  group('VerseTiming', () {
    final fatiha = SurahModel(number: 1, nameArabic: '', namePulaar: '', verses: [
      VerseModel(number: 1, arabic: 'aaaa', pulaar: ''),
      VerseModel(number: 2, arabic: 'aaaaaaaaaaaa', pulaar: ''),
    ]);

    test('proportionnel à la longueur arabe', () {
      final t = VerseTiming(fatiha, const Duration(seconds: 16));
      expect(t.startOf(0), Duration.zero);
      expect(t.startOf(1), const Duration(seconds: 4));
      expect(t.endOf(1), const Duration(seconds: 16));
      expect(t.indexAt(const Duration(seconds: 5)), 1);
    });

    test('Basmala avant le premier verset (hors Al-Fatiha)', () {
      final other = SurahModel(number: 112, nameArabic: '', namePulaar: '', verses: fatiha.verses);
      final t = VerseTiming(other, const Duration(seconds: 60));
      expect(t.indexAt(Duration.zero), -1);
      expect(t.startOf(0), greaterThan(Duration.zero));
    });
  });
}
