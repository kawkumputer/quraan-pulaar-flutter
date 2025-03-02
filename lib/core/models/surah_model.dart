

class SurahModel {
  final int number;
  final int juzNumber;
  final String nameArabic;
  final String namePulaar;
  final int versesCount;
  final String audioUrl;
  final List<VerseModel> verses;

  SurahModel({
    required this.number,
    required this.juzNumber,
    required this.nameArabic,
    required this.namePulaar,
    required this.versesCount,
    required this.audioUrl,
    required this.verses,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] as int,
      juzNumber: json['juzz_number'] as int,
      nameArabic: json['arabic'] as String,
      namePulaar: json['pulaar'] as String,
      versesCount: json['total_verses'] as int,
      audioUrl: json['audio_url'] as String,
      verses: (json['verses'] as List<dynamic>)
          .map((verse) => VerseModel.fromJson(verse))
          .toList(),
    );
  }

}

class VerseModel {
  final int number;
  final String arabic;
  final String pulaar;

  VerseModel({
    required this.number,
    required this.arabic,
    required this.pulaar,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      number: json['number'] as int,
      arabic: json['arabic'] as String,
      pulaar: json['pulaar'] as String,
    );
  }

}
