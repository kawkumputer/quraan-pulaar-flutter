import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';

class DownloadService extends GetxService {
  final Map<int, RxBool> _downloadedSurahs = {};
  final Map<int, RxBool> _downloadingSurahs = {};
  
  DownloadService() {
    init();
  }
  
  Future<String> get _downloadDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${appDir.path}/audio_downloads');
    if (!await downloadDir.exists()) {
      await downloadDir.create(recursive: true);
    }
    return downloadDir.path;
  }

  Future<void> init() async {
    // Check existing downloads
    final dir = await _downloadDir;
    final directory = Directory(dir);
    if (await directory.exists()) {
      final files = directory.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.mp3')) {
          final fileName = file.path.split('/').last;
          final surahNumber = int.tryParse(fileName.split('.').first);
          if (surahNumber != null) {
            _downloadedSurahs[surahNumber] = RxBool(true);
          }
        }
      }
    }
  }

  bool isDownloaded(int surahNumber) {
    return _downloadedSurahs[surahNumber]?.value ?? false;
  }

  bool isDownloading(int surahNumber) {
    return _downloadingSurahs[surahNumber]?.value ?? false;
  }

  Future<String?> getOfflineUrl(int surahNumber) async {
    final dir = await _downloadDir;
    final file = File('$dir/$surahNumber.mp3');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  Future<bool> downloadSurah(SurahModel surah) async {
    if (isDownloaded(surah.number) || isDownloading(surah.number)) {
      return true;
    }

    try {
      _downloadingSurahs[surah.number] = RxBool(true);
      
      final response = await http.get(Uri.parse(surah.audioUrl));
      if (response.statusCode == 200) {
        final dir = await _downloadDir;
        final file = File('$dir/${surah.number}.mp3');
        await file.writeAsBytes(response.bodyBytes);
        
        _downloadedSurahs[surah.number] = RxBool(true);
        _downloadingSurahs[surah.number] = RxBool(false);
        return true;
      }
    } catch (e) {
      print('Error downloading surah ${surah.number}: $e');
    }
    
    _downloadingSurahs[surah.number] = RxBool(false);
    return false;
  }

  Future<void> deleteSurah(int surahNumber) async {
    try {
      final dir = await _downloadDir;
      final file = File('$dir/$surahNumber.mp3');
      if (await file.exists()) {
        await file.delete();
        _downloadedSurahs[surahNumber]?.value = false;
      }
    } catch (e) {
      print('Error deleting surah $surahNumber: $e');
    }
  }
}
