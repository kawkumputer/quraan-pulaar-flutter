import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'surah.g.dart';

@HiveType(typeId: 0)
class Surah {
  @HiveField(0)
  final int number;
  
  @HiveField(1)
  final int juzNumber;
  
  @HiveField(2)
  final String nameArabic;
  
  @HiveField(3)
  final String namePulaar;
  
  @HiveField(4)
  final int versesCount;
  
  @HiveField(5)
  final String audioUrl;
  
  @HiveField(6)
  final List<Verse> verses;

  Surah({
    required this.number,
    required this.juzNumber,
    required this.nameArabic,
    required this.namePulaar,
    required this.versesCount,
    required this.audioUrl,
    required this.verses,
  });

  factory Surah.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> ayats = data['ayats'] ?? [];

    return Surah(
      number: data['suratNumber'] ?? 0,
      juzNumber: data['juzzNumber'] ?? 0,
      nameArabic: data['arabeTitle'] ?? '',
      namePulaar: data['pulaarTitle'] ?? '',
      versesCount: data['ayatsNumber'] ?? 0,
      audioUrl: data['sourateUrl'] ?? '',
      verses: ayats.map((ayat) => Verse.fromMap(ayat as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'juzNumber': juzNumber,
      'nameArabic': nameArabic,
      'namePulaar': namePulaar,
      'versesCount': versesCount,
      'audioUrl': audioUrl,
      'verses': verses.map((v) => v.toJson()).toList(),
    };
  }

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] as int,
      juzNumber: json['juzNumber'] as int,
      nameArabic: json['nameArabic'] as String,
      namePulaar: json['namePulaar'] as String,
      versesCount: json['versesCount'] as int,
      audioUrl: json['audioUrl'] as String,
      verses: (json['verses'] as List).map((v) => Verse.fromJson(v as Map<String, dynamic>)).toList(),
    );
  }
}

@HiveType(typeId: 1)
class Verse {
  @HiveField(0)
  final String arabic;
  
  @HiveField(1)
  final String pulaar;
  
  @HiveField(2)
  final int number;
  
  @HiveField(3)
  final String audioUrl;

  Verse({
    required this.arabic,
    required this.pulaar,
    required this.number,
    required this.audioUrl,
  });

  factory Verse.fromMap(Map<String, dynamic> map) {
    return Verse(
      arabic: map['arabe'] ?? '',
      pulaar: map['pulaar'] ?? '',
      number: map['number'] ?? 0,
      audioUrl: map['audioUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arabic': arabic,
      'pulaar': pulaar,
      'number': number,
      'audioUrl': audioUrl,
    };
  }

  factory Verse.fromJson(Map<String, dynamic> json) {
    return Verse(
      arabic: json['arabic'] as String,
      pulaar: json['pulaar'] as String,
      number: json['number'] as int,
      audioUrl: json['audioUrl'] as String,
    );
  }
}
