/// Compare deux versions « x.y.z » (les suffixes +build ou -beta sont ignorés).
/// Renvoie < 0 si [a] < [b], 0 si égales, > 0 si [a] > [b].
int compareVersions(String a, String b) {
  List<int> parse(String v) => v
      .split(RegExp(r'[+\-]'))
      .first
      .split('.')
      .map((p) => int.tryParse(p.trim()) ?? 0)
      .toList();

  final pa = parse(a);
  final pb = parse(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}
