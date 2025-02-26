import 'package:cloud_firestore/cloud_firestore.dart';

class AudioSurah {
  final int number;
  final String name;
  final String arabicName;
  final String audioUrl;
  final int versesCount;
  bool isPlaying;
  bool isDownloaded;

  AudioSurah({
    required this.number,
    required this.name,
    required this.arabicName,
    required this.audioUrl,
    required this.versesCount,
    this.isPlaying = false,
    this.isDownloaded = false,
  });

  factory AudioSurah.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AudioSurah(
      number: data['number'] as int,
      name: data['nameEn'] as String,
      arabicName: data['nameAr'] as String,
      audioUrl: data['audioUrl'] ?? '',
      versesCount: data['versesCount'] as int,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'number': number,
      'nameEn': name,
      'nameAr': arabicName,
      'audioUrl': audioUrl,
      'versesCount': versesCount,
    };
  }
}
