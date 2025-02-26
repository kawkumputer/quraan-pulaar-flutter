import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';

class BookmarkService extends GetxService {
  static const String _bookmarksKey = 'bookmarks';
  final RxList<int> _bookmarkedSurahs = <int>[].obs;
  SharedPreferences? _prefs;

  List<int> get bookmarkedSurahs => _bookmarkedSurahs.toList();

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
    _bookmarkedSurahs.value = bookmarks.map((e) => int.parse(e)).toList();
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

class Bookmark {
  final int surahNumber;
  final String surahName;
  final int verseNumber;
  final DateTime timestamp;

  Bookmark({
    required this.surahNumber,
    required this.surahName,
    required this.verseNumber,
    required this.timestamp,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      surahNumber: json['surahNumber'],
      surahName: json['surahName'],
      verseNumber: json['verseNumber'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surahNumber': surahNumber,
      'surahName': surahName,
      'verseNumber': verseNumber,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
