import 'package:flutter_test/flutter_test.dart';
import 'package:quraan_pulaar/core/constants/strings.dart';
import 'package:quraan_pulaar/core/l10n/app_language.dart';
import 'package:quraan_pulaar/core/models/surah_model.dart';

void main() {
  tearDown(() => CurrentLanguage.value = AppLanguage.pulaar);

  test('les textes suivent la langue courante', () {
    CurrentLanguage.value = AppLanguage.pulaar;
    expect(S.retry, 'Fuɗɗito');
    CurrentLanguage.value = AppLanguage.french;
    expect(S.retry, 'Réessayer');
    CurrentLanguage.value = AppLanguage.arabic;
    expect(S.retry, 'إعادة المحاولة');
  });

  test("nom de sourate en arabe uniquement en interface arabe", () {
    final s = SurahModel(number: 112, nameArabic: 'الإخلاص', namePulaar: 'Al-Ikhlaas', verses: const []);
    CurrentLanguage.value = AppLanguage.french;
    expect(S.surahName(s), 'Al-Ikhlaas');
    CurrentLanguage.value = AppLanguage.arabic;
    expect(S.surahName(s), 'الإخلاص');
  });

  test('locale Material : français pour le Pulaar, arabe en RTL', () {
    expect(AppLanguage.pulaar.materialLocale.languageCode, 'fr');
    expect(AppLanguage.arabic.isRtl, isTrue);
    expect(AppLanguage.fromCode('fr'), AppLanguage.french);
    expect(AppLanguage.fromCode(null), isNull);
  });
}
