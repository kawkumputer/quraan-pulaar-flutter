import '../../features/surah/models/surah.dart';
import 'verse_model.dart';

class SurahModel {
  final int number;
  final String nameArabic;
  final String namePulaar;
  final List<VerseModel> verses;
  final int versesCount;
  final String audioUrl;

  SurahModel({
    required this.number,
    required this.nameArabic,
    required this.namePulaar,
    required this.verses,
    this.versesCount = 0,
    this.audioUrl = '',
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final verses = (json['verses'] as List)
        .map((verse) => VerseModel.fromJson(verse))
        .toList();
        
    return SurahModel(
      number: json['number'],
      nameArabic: json['arabic'] ?? '',
      namePulaar: json['pulaar'] ?? '',
      verses: verses,
      versesCount: json['total_verses'] ?? verses.length,
      audioUrl: json['audio_url'] ?? '',
    );
  }

  factory SurahModel.fromFirebase(Surah surah) {
    final verses = surah.verses.map((verse) => VerseModel.fromFirebase(verse)).toList();
    
    return SurahModel(
      number: surah.number,
      nameArabic: surah.nameArabic,
      namePulaar: surah.namePulaar,
      verses: verses,
      versesCount: verses.length,
      audioUrl: surah.audioUrl ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'nameArabic': nameArabic,
      'namePulaar': namePulaar,
      'verses': verses.map((verse) => verse.toJson()).toList(),
      'versesCount': versesCount,
      'audioUrl': audioUrl,
    };
  }
}
