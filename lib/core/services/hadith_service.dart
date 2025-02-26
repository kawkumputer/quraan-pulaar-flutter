import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/hadith/models/hadith.dart';

class HadithService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Hadith>> getAllHadiths() async {
    try {
      final QuerySnapshot snapshot = await _firestore.collection('hadiis').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Hadith.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching hadiths: $e');
      return [];
    }
  }

  Future<Hadith?> getHadithById(int id) async {
    try {
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
