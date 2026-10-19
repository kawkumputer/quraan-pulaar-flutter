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
    SurahModel surah(int number, List<List<String>> verses) => SurahModel(
          number: number,
          nameArabic: '',
          namePulaar: '',
          verses: [
            for (var i = 0; i < verses.length; i++)
              VerseModel(number: i + 1, arabic: verses[i][0], pulaar: verses[i][1]),
          ],
        );

    test('introduction avant le premier verset', () {
      final t = VerseTiming(surah(1, [['قل', 'Wiy'], ['هو', 'Ko']]), const Duration(seconds: 60));
      expect(t.indexAt(Duration.zero), -1);
      expect(t.startOf(0), greaterThan(Duration.zero));
    });

    test('la traduction Pulaar compte dans la durée du verset', () {
      final shortPulaar = VerseTiming(
          surah(1, [['قل', 'a'], ['قل', 'a']]), const Duration(seconds: 60));
      final longPulaar = VerseTiming(
          surah(1, [['قل', 'a' * 40], ['قل', 'a']]), const Duration(seconds: 60));
      // Verset 1 plus long => le verset 2 commence plus tard.
      expect(longPulaar.startOf(1), greaterThan(shortPulaar.startOf(1)));
    });

    test('les voyelles arabes ne rallongent pas un verset', () {
      final withHarakat = VerseTiming(
          surah(1, [['قُلْ هُوَ', ''], ['احد', '']]), const Duration(seconds: 60));
      final without = VerseTiming(
          surah(1, [['قل هو', ''], ['احد', '']]), const Duration(seconds: 60));
      expect(withHarakat.startOf(1), without.startOf(1));
    });

    test('Basmala en plus hors Al-Fatiha', () {
      final verses = [['قل', 'Wiy']];
      final fatiha = VerseTiming(surah(1, verses), const Duration(seconds: 60));
      final other = VerseTiming(surah(112, verses), const Duration(seconds: 60));
      expect(other.startOf(0), greaterThan(fatiha.startOf(0)));
    });
  });
}
