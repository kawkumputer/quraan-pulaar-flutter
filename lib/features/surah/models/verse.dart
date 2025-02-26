class Verse {
  final int number;
  final String arabic;
  final String pulaar;

  Verse({
    required this.number,
    required this.arabic,
    required this.pulaar,
  });

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      number: json['number'] as int? ?? 0,
      arabic: json['arabic'] as String? ?? '',
      pulaar: json['pulaar'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'arabic': arabic,
      'pulaar': pulaar,
    };
  }
}
