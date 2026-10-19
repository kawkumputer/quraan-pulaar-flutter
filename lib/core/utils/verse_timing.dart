import '../models/surah_model.dart';

const String kBasmalaArabic = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';

/// Minutage estimé des versets dans l'audio d'une sourate : chaque verset dure
/// proportionnellement à la longueur de son texte arabe (la Basmala ouvre toutes
/// les sourates sauf Al-Fatiha). Approximation, faute de minutage réel.
class VerseTiming {
  final List<Duration> _starts;
  final Duration total;

  VerseTiming._(this._starts, this.total);

  factory VerseTiming(SurahModel surah, Duration total) {
    final hasBasmala = surah.number != 1;
    var totalLength = surah.verses.fold<int>(0, (sum, v) => sum + v.arabic.length);
    if (hasBasmala) totalLength += kBasmalaArabic.length;
    if (totalLength == 0) return VerseTiming._([], total);

    final ms = total.inMilliseconds;
    var current = hasBasmala ? kBasmalaArabic.length / totalLength * ms : 0.0;
    final starts = <Duration>[];
    for (final verse in surah.verses) {
      starts.add(Duration(milliseconds: current.round()));
      current += verse.arabic.length / totalLength * ms;
    }
    return VerseTiming._(starts, total);
  }

  int get length => _starts.length;

  /// Index du verset en cours à [position] ; -1 pendant la Basmala.
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
