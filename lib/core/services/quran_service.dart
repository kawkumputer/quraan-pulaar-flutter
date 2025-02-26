import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../models/surah_model.dart';

class QuranService extends GetxController {
  final _surahs = <SurahModel>[].obs;
  final _currentSurah = Rxn<SurahModel>();
  final _currentVerseIndex = 0.obs;
  final _isLoading = false.obs;
  final _error = Rxn<String>();

  List<SurahModel> get surahs => _surahs;
  SurahModel? get currentSurah => _currentSurah.value;
  int get currentVerseIndex => _currentVerseIndex.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    loadSurahs();
  }

  Future<void> loadSurahs() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      _surahs.clear();

      print('Attempting to load surahs.json...');
      final ByteData data = await rootBundle.load('assets/data/surahs.json');
      final String jsonString = utf8.decode(data.buffer.asUint8List());
      print('Successfully loaded JSON file');
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      print('Successfully parsed JSON');
      
      if (!jsonData.containsKey('surahs')) {
        throw 'Invalid JSON format: missing "surahs" key';
      }

      final List<dynamic> surahsData = jsonData['surahs'];
      print('Found ${surahsData.length} surahs in JSON');
      
      _surahs.value = surahsData.map((surah) {
        final model = SurahModel.fromJson(surah);
        print('Loaded surah ${model.number}: ${model.namePulaar} (${model.nameArabic})');
        return model;
      }).toList();
      
      if (_surahs.isEmpty) {
        throw 'No surahs found in the JSON file';
      }

      print('Successfully loaded ${_surahs.length} surahs');
    } catch (e, stackTrace) {
      print('Error loading surahs: $e');
      print('Stack trace: $stackTrace');
      _error.value = 'Failed to load surahs: $e';
      _surahs.clear();
    } finally {
      _isLoading.value = false;
    }
  }

  List<SurahModel> searchSurahs(String query) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return _surahs.where((surah) {
      final numberMatch = surah.number.toString().contains(query);
      final nameMatch = surah.namePulaar.toLowerCase().contains(lowercaseQuery) ||
                       surah.nameArabic.contains(query);
      
      // Also search in verses if there's a match in the text or translation
      final versesMatch = surah.verses.any((verse) =>
        verse.pulaarTranslation.toLowerCase().contains(lowercaseQuery) ||
        verse.arabic.contains(query)
      );
      
      return numberMatch || nameMatch || versesMatch;
    }).toList();
  }

  void setCurrentSurah(SurahModel surah) {
    _currentSurah.value = surah;
    _currentVerseIndex.value = 0;
  }

  void setCurrentVerse(int index) {
    if (currentSurah != null && index >= 0 && index < currentSurah!.verses.length) {
      _currentVerseIndex.value = index;
    }
  }

  void nextVerse() {
    if (currentSurah != null && currentVerseIndex < currentSurah!.verses.length - 1) {
      _currentVerseIndex.value++;
    }
  }

  void previousVerse() {
    if (currentSurah != null && currentVerseIndex > 0) {
      _currentVerseIndex.value--;
    }
  }
}
