import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/audio/models/audio_surah.dart';

class AudioFirestoreService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<AudioSurah>> loadAudioSurahs() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('surahs')
          .orderBy('number')
          .get();

      return snapshot.docs
          .map((doc) => AudioSurah.fromFirestore(doc))
          .where((surah) => surah.audioUrl.isNotEmpty)
          .toList();
    } catch (e) {
      print('Error loading audio surahs: $e');
      return [];
    }
  }

  Future<void> updateSurahAudio(int surahNumber, String audioUrl) async {
    try {
      await _firestore.collection('surahs').doc(surahNumber.toString()).update({
        'audioUrl': audioUrl,
      });
    } catch (e) {
      print('Error updating surah audio: $e');
      rethrow;
    }
  }
}
