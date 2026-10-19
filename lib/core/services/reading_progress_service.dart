import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dernière position de lecture (sourate + index du verset), pour « continuer la lecture ».
class ReadingProgress {
  final int surahNumber;
  final int verseIndex;

  const ReadingProgress(this.surahNumber, this.verseIndex);
}

class ReadingProgressService extends GetxService {
  static const _surahKey = 'last_read_surah';
  static const _verseKey = 'last_read_verse';

  final last = Rxn<ReadingProgress>();
  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final surah = _prefs!.getInt(_surahKey);
    if (surah != null) {
      last.value = ReadingProgress(surah, _prefs!.getInt(_verseKey) ?? 0);
    }
  }

  Future<void> save(int surahNumber, int verseIndex) async {
    final current = last.value;
    if (current?.surahNumber == surahNumber && current?.verseIndex == verseIndex) return;
    last.value = ReadingProgress(surahNumber, verseIndex);
    await _prefs?.setInt(_surahKey, surahNumber);
    await _prefs?.setInt(_verseKey, verseIndex);
  }
}
