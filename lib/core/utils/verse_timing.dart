import '../models/surah_model.dart';
import 'text_normalizer.dart';

const String kBasmalaArabic = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
const String kBasmalaPulaar = 'E innde alla Jurumdeero Jurmotooɗo';

/// Réglages de l'estimation (à affiner en écoutant) :
/// l'audio d'une sourate = introduction, Basmala (sauf Al-Fatiha), puis pour
/// chaque verset la récitation arabe suivie de la lecture en Pulaar.
class VerseTimingConfig {
  /// Poids d'une lettre arabe (sans voyelles) par rapport à un caractère Pulaar :
  /// la récitation est plus lente que la lecture.
  static const double arabicLetterWeight = 1.6;
  static const double pulaarCharWeight = 1.0;

  /// Introduction avant la Basmala (« A'oudhou billahi… » et sa traduction).
  /// Textes utilisés seulement pour leur longueur (jamais affichés).
  static const String introArabic = 'أعوذ بالله من الشيطان الرجيم';
  static const String introPulaar = 'Mi hoolike e Alla e kala bonɗo Seytaane jeertaaɗo';
}

/// Minutage estimé des versets dans l'audio d'une sourate, faute de minutage réel :
/// chaque segment dure proportionnellement à son « poids » de texte.
class VerseTiming {
  final List<Duration> _starts;
  final Duration total;

  VerseTiming._(this._starts, this.total);

  static double _weight(String arabic, String pulaar) {
    final letters = TextNormalizer.normalize(arabic).replaceAll(RegExp(r'\s'), '').length;
    final pulaarChars = pulaar.replaceAll(RegExp(r'\s'), '').length;
    return letters * VerseTimingConfig.arabicLetterWeight +
        pulaarChars * VerseTimingConfig.pulaarCharWeight;
  }

  factory VerseTiming(SurahModel surah, Duration total) {
    var before = _weight(VerseTimingConfig.introArabic, VerseTimingConfig.introPulaar);
    if (surah.number != 1) before += _weight(kBasmalaArabic, kBasmalaPulaar);

    final weights = [for (final v in surah.verses) _weight(v.arabic, v.pulaar)];
    final totalWeight = before + weights.fold<double>(0, (a, b) => a + b);
    if (weights.isEmpty || totalWeight == 0) return VerseTiming._([], total);

    final ms = total.inMilliseconds;
    var current = before / totalWeight * ms;
    final starts = <Duration>[];
    for (final w in weights) {
      starts.add(Duration(milliseconds: current.round()));
      current += w / totalWeight * ms;
    }
    return VerseTiming._(starts, total);
  }

  int get length => _starts.length;

  /// Index du verset en cours à [position] ; -1 pendant l'introduction / la Basmala.
  int indexAt(Duration position) {
    if (_starts.isEmpty || position < _starts.first) return -1;
    var index = 0;
    for (var i = 0; i < _starts.length; i++) {
      if (_starts[i] <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }

  Duration startOf(int index) => _starts[index.clamp(0, _starts.length - 1)];

  Duration endOf(int index) =>
      index + 1 < _starts.length ? _starts[index + 1] : total;
}
