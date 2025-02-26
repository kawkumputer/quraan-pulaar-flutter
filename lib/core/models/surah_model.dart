import 'dart:convert';

class SurahModel {
  final int number;
  final String nameArabic;
  final String namePulaar;
  final String nameTranslation;
  final int versesCount;
  final List<VerseModel> verses;

  SurahModel({
    required this.number,
    required this.nameArabic,
    required this.namePulaar,
    required this.nameTranslation,
    required this.versesCount,
    required this.verses,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    return SurahModel(
      number: json['number'] as int,
      nameArabic: json['name']['arabic'] as String,
      namePulaar: json['name']['pulaar'] as String,
      nameTranslation: json['name']['translation'] as String,
      versesCount: json['total_verses'] as int,
      verses: (json['verses'] as List<dynamic>)
          .map((verse) => VerseModel.fromJson(verse))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'name': {
        'arabic': nameArabic,
        'pulaar': namePulaar,
        'translation': nameTranslation,
      },
      'total_verses': versesCount,
      'verses': verses.map((verse) => verse.toJson()).toList(),
    };
  }
}

class VerseModel {
  final int number;
  final String arabic;
  final String englishTranslation;
  final String pulaarTranslation;
  final String audioUrl;

  VerseModel({
    required this.number,
    required this.arabic,
    required this.englishTranslation,
    required this.pulaarTranslation,
    required this.audioUrl,
  });

  factory VerseModel.fromJson(Map<String, dynamic> json) {
    return VerseModel(
      number: json['number'] as int,
      arabic: json['text']['arabic'] as String,
      englishTranslation: json['translation']['english'] as String,
      pulaarTranslation: json['translation']['pulaar'] as String,
      audioUrl: json['audio'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'text': {
        'arabic': arabic,
      },
      'translation': {
        'english': englishTranslation,
        'pulaar': pulaarTranslation,
      },
      'audio': audioUrl,
    };
  }
}
