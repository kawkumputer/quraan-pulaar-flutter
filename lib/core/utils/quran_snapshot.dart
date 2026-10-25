import '../models/surah_model.dart';
import '../models/verse_model.dart';

/// Copie locale du texte du Coran reçu de Supabase (fonction quran_sync).
///
/// Ne contient que ce à quoi l'appareil a droit : les sourates gratuites, ou tout
/// le Coran si l'appareil est activé. Les synchronisations suivantes n'apportent
/// que les versets modifiés depuis [serverTime].
class QuranSnapshot {
  /// Heure du serveur lors de la dernière synchronisation (repère pour la suivante).
  final DateTime? serverTime;

  /// État d'activation au moment de la synchronisation.
  final bool activated;

  final Map<int, Map<String, dynamic>> surahs;

  /// sourate -> verset -> [arabe, pulaar]
  final Map<int, Map<int, List<String>>> verses;

  const QuranSnapshot({
    required this.serverTime,
    required this.activated,
    required this.surahs,
    required this.verses,
  });

  static const empty = QuranSnapshot(serverTime: null, activated: false, surahs: {}, verses: {});

  bool get isEmpty => surahs.isEmpty;

  /// Applique une réponse de quran_sync. [response] contient la totalité du contenu
  /// si [full], sinon seulement les changements depuis [serverTime].
  QuranSnapshot apply(Map<String, dynamic> response, {required bool full}) {
    final surahs = full ? <int, Map<String, dynamic>>{} : {...this.surahs};
    final verses = full
        ? <int, Map<int, List<String>>>{}
        : {for (final e in this.verses.entries) e.key: {...e.value}};

    for (final s in (response['surahs'] as List? ?? const [])) {
      final map = Map<String, dynamic>.from(s as Map);
      surahs[map['number'] as int] = map;
    }
    for (final v in (response['verses'] as List? ?? const [])) {
      final map = v as Map;
      final s = map['s'] as int;
      verses.putIfAbsent(s, () => {})[map['n'] as int] = [
        map['ar'] as String? ?? '',
        map['ff'] as String? ?? '',
      ];
    }

    return QuranSnapshot(
      serverTime: DateTime.tryParse(response['server_time'] as String? ?? '') ?? serverTime,
      activated: response['activated'] == true,
      surahs: surahs,
      verses: verses,
    );
  }

  /// Corrige la traduction d'un verset localement (mode correcteur).
  QuranSnapshot withPulaar(int surah, int verse, String pulaar) {
    final current = verses[surah]?[verse];
    if (current == null) return this;
    final copy = {for (final e in verses.entries) e.key: {...e.value}};
    copy[surah]![verse] = [current[0], pulaar];
    return QuranSnapshot(serverTime: serverTime, activated: activated, surahs: surahs, verses: copy);
  }

  List<SurahModel> toModels() {
    final numbers = surahs.keys.toList()..sort();
    return [
      for (final n in numbers)
        () {
          final meta = surahs[n]!;
          final vs = verses[n] ?? const {};
          final keys = vs.keys.toList()..sort();
          return SurahModel(
            number: n,
            nameArabic: meta['name_arabic'] as String? ?? '',
            namePulaar: meta['name_pulaar'] as String? ?? '',
            audioUrl: meta['audio_url'] as String? ?? '',
            versesCount: (meta['verses_count'] as int?) ?? keys.length,
            verses: [
              for (final k in keys) VerseModel(number: k, arabic: vs[k]![0], pulaar: vs[k]![1]),
            ],
          );
        }(),
    ];
  }

  Map<String, dynamic> toJson() => {
        'server_time': serverTime?.toIso8601String(),
        'activated': activated,
        'surahs': surahs.values.toList(),
        'verses': [
          for (final s in verses.entries)
            for (final v in s.value.entries) [s.key, v.key, v.value[0], v.value[1]],
        ],
      };

  factory QuranSnapshot.fromJson(Map<String, dynamic> json) {
    final verses = <int, Map<int, List<String>>>{};
    for (final row in (json['verses'] as List? ?? const [])) {
      final r = row as List;
      verses.putIfAbsent(r[0] as int, () => {})[r[1] as int] = [r[2] as String, r[3] as String];
    }
    return QuranSnapshot(
      serverTime: DateTime.tryParse(json['server_time'] as String? ?? ''),
      activated: json['activated'] == true,
      surahs: {
        for (final s in (json['surahs'] as List? ?? const []))
          (s as Map)['number'] as int: Map<String, dynamic>.from(s),
      },
      verses: verses,
    );
  }
}
