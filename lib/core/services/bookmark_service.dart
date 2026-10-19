import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verset mis en favori (index 0-based du verset dans la sourate).
class VerseBookmark {
  final int surahNumber;
  final int verseIndex;

  const VerseBookmark(this.surahNumber, this.verseIndex);

  String get key => '$surahNumber:$verseIndex';

  static VerseBookmark? parse(String key) {
    final parts = key.split(':');
    final s = int.tryParse(parts.first);
    final v = parts.length > 1 ? int.tryParse(parts[1]) : null;
    return (s == null || v == null) ? null : VerseBookmark(s, v);
  }
}

class BookmarkService extends GetxService {
  static const String _bookmarksKey = 'bookmarks';
  static const String _verseBookmarksKey = 'verse_bookmarks';
  final RxList<int> _bookmarkedSurahs = <int>[].obs;
  /// Clés « sourate:verset », les plus récentes en premier.
  final RxList<String> _verseBookmarks = <String>[].obs;
  SharedPreferences? _prefs;

  List<int> get bookmarkedSurahs => _bookmarkedSurahs.toList();
  List<VerseBookmark> get verseBookmarks =>
      _verseBookmarks.map(VerseBookmark.parse).whereType<VerseBookmark>().toList();

  bool isVerseBookmarked(int surahNumber, int verseIndex) =>
      _verseBookmarks.contains(VerseBookmark(surahNumber, verseIndex).key);

  Future<void> toggleVerseBookmark(int surahNumber, int verseIndex) async {
    final key = VerseBookmark(surahNumber, verseIndex).key;
    if (!_verseBookmarks.remove(key)) {
      _verseBookmarks.insert(0, key);
    }
    await _prefs?.setStringList(_verseBookmarksKey, _verseBookmarks.toList());
  }

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    if (_prefs == null) return;
    final bookmarks = _prefs!.getStringList(_bookmarksKey) ?? [];
    _bookmarkedSurahs.value = bookmarks.map(int.tryParse).whereType<int>().toList();
    _verseBookmarks.value = _prefs!.getStringList(_verseBookmarksKey) ?? [];
  }

  Future<void> _saveBookmarks() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(
      _bookmarksKey,
      _bookmarkedSurahs.map((e) => e.toString()).toList(),
    );
  }

  Future<void> toggleBookmark(int surahNumber) async {
    if (_bookmarkedSurahs.contains(surahNumber)) {
      _bookmarkedSurahs.remove(surahNumber);
    } else {
      _bookmarkedSurahs.add(surahNumber);
    }
    await _saveBookmarks();
  }

  bool isBookmarked(int surahNumber) {
    return _bookmarkedSurahs.contains(surahNumber);
  }
}
