import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../features/hadith/models/hadith.dart';
import './settings_service.dart';

class HadithService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SettingsService _settingsService = Get.find<SettingsService>();

  // Free hadiths that are available without activation
  final List<Map<String, dynamic>> _freeHadiths = [
    {
      'id': 1,
      'url': 'https://firebasestorage.googleapis.com/v0/b/quran-pulaar-dmwdqo.firebasestorage.app/o/hadiis%2Fhadith_1.mp3?alt=media&token=846dc8eb-0763-4f2d-99eb-81f91945a44b'
    },
    {
      'id': 2,
      'url': 'https://firebasestorage.googleapis.com/v0/b/quran-pulaar-dmwdqo.firebasestorage.app/o/hadiis%2Fhadith_2.mp3?alt=media&token=10a3bf08-9cb6-46c8-abcc-83971e60ced3'
    },
    {
      'id': 3,
      'url': 'https://firebasestorage.googleapis.com/v0/b/quran-pulaar-dmwdqo.firebasestorage.app/o/hadiis%2Fhadith_2.mp3?alt=media&token=10a3bf08-9cb6-46c8-abcc-83971e60ced3'
    }
  ];

  Future<List<Hadith>> getAllHadiths() async {
    try {
      if (!_settingsService.isActivated) {
        // Return only free hadiths for non-activated devices
        return _freeHadiths.map((data) => Hadith.fromJson(data)).toList();
      }

      // Return all hadiths for activated devices
      final QuerySnapshot snapshot = await _firestore.collection('hadiis').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Hadith.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching hadiths: $e');
      // Fallback to free hadiths in case of error
      return _freeHadiths.map((data) => Hadith.fromJson(data)).toList();
    }
  }

  Future<Hadith?> getHadithById(int id) async {
    try {
      // For non-activated devices, check if the hadith is free
      if (!_settingsService.isActivated) {
        final freeHadith = _freeHadiths.firstWhere(
          (h) => h['id'] == id,
          orElse: () => Map<String, dynamic>.from({}),
        );
        if (freeHadith.isEmpty) return null;
        return Hadith.fromJson(freeHadith);
      }

      // For activated devices, fetch from Firebase
      final QuerySnapshot snapshot = await _firestore
          .collection('hadiis')
          .where('id', isEqualTo: id)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final data = snapshot.docs.first.data() as Map<String, dynamic>;
      return Hadith.fromJson(data);
    } catch (e) {
      print('Error fetching hadith: $e');
      return null;
    }
  }
}
