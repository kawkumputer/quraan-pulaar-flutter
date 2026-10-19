/// Normalisation pour la recherche : insensible à la casse, aux diacritiques
/// arabes et aux lettres spéciales du Pulaar.
class TextNormalizer {
  static const Map<String, String> _map = {
    // Pulaar
    'ɓ': 'b', 'Ɓ': 'b', 'ɗ': 'd', 'Ɗ': 'd', 'ŋ': 'n', 'Ŋ': 'n',
    'ƴ': 'y', 'Ƴ': 'y', 'ñ': 'n', 'Ñ': 'n',
    // Accents latins courants
    'à': 'a', 'â': 'a', 'á': 'a', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ó': 'o', 'û': 'u', 'ù': 'u',
    'ú': 'u', 'ç': 'c',
    // Arabe : variantes de lettres
    'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ى': 'ي', 'ة': 'ه',
    'ؤ': 'و', 'ئ': 'ي',
  };

  /// Caractères supprimés : diacritiques arabes, tatweel, apostrophes.
  static bool _isDropped(int c) =>
      (c >= 0x064B && c <= 0x065F) || // harakat
      c == 0x0670 || // alef suscrit
      (c >= 0x06D6 && c <= 0x06ED) || // signes coraniques
      c == 0x0640 || // tatweel
      c == 0x0027 || c == 0x2019 || c == 0x02BC; // apostrophes

  static String normalize(String input) => normalizeWithMap(input).$1;

  /// Texte normalisé et, pour chaque caractère du résultat, son index dans
  /// [input] (pour surligner la correspondance dans le texte d'origine).
  static (String, List<int>) normalizeWithMap(String input) {
    final out = StringBuffer();
    final map = <int>[];
    var i = 0;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      if (!_isDropped(rune)) {
        final mapped = _map[char] ?? char.toLowerCase();
        for (var k = 0; k < mapped.length; k++) {
          map.add(i);
        }
        out.write(mapped);
      }
      i += char.length;
    }
    return (out.toString(), map);
  }

  /// Plage [début, fin[ dans [original] correspondant à la première occurrence
  /// de [normalizedQuery], ou null.
  static (int, int)? findInOriginal(String original, String normalizedQuery) {
    if (normalizedQuery.isEmpty) return null;
    final (norm, map) = normalizeWithMap(original);
    final start = norm.indexOf(normalizedQuery);
    if (start < 0) return null;
    // La fin s'étend jusqu'au caractère conservé suivant : les diacritiques
    // attachés à la dernière lettre sont inclus.
    final next = start + normalizedQuery.length;
    final origEnd = next < map.length ? map[next] : original.length;
    return (map[start], origEnd);
  }
}
