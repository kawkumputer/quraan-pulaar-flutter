import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/surah_model.dart';

class DownloadService extends GetxService {
  final _downloadedSurahs = <int, bool>{}.obs;
  final _downloadingSurahs = <int, bool>{}.obs;
  final _downloadProgress = <int, double>{}.obs;
  
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
    try {
      // Check existing downloads
      final dir = await _downloadDir;
      final directory = Directory(dir);
      if (await directory.exists()) {
        final files = directory.listSync();
        for (var file in files) {
          if (file is File && file.path.endsWith('.mp3')) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            final surahNumber = int.tryParse(fileName.split('.').first);
            if (surahNumber != null) {
              _downloadedSurahs[surahNumber] = true;
              _downloadProgress[surahNumber] = 1.0; // 100% for completed downloads
            }
          }
        }
      }
    } catch (e) {
      print('Error initializing DownloadService: $e');
    }
  }

  bool isDownloaded(int surahNumber) {
    return _downloadedSurahs[surahNumber] ?? false;
  }

  bool isDownloading(int surahNumber) {
    return _downloadingSurahs[surahNumber] ?? false;
  }

  double getProgress(int surahNumber) {
    return _downloadProgress[surahNumber] ?? 0.0;
  }

  Future<String?> getOfflineUrl(int surahNumber) async {
    try {
      final dir = await _downloadDir;
      final file = File('$dir${Platform.pathSeparator}$surahNumber.mp3');
      if (await file.exists()) {
        // For iOS, use file:// scheme
        if (Platform.isIOS) {
          return 'file://${file.path}';
        }
        return file.path;
      }
    } catch (e) {
      print('Error getting offline URL: $e');
    }
    return null;
  }

  Future<bool> downloadSurah(SurahModel surah) async {
    if (isDownloaded(surah.number) || isDownloading(surah.number)) {
      return true;
    }

    try {
      _downloadingSurahs[surah.number] = true;
      _downloadProgress[surah.number] = 0.0;
      
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(surah.audioUrl));
      final response = await client.send(request);
      
      if (response.statusCode == 200) {
        final dir = await _downloadDir;
        final file = File('$dir${Platform.pathSeparator}${surah.number}.mp3');
        final sink = file.openWrite();
        
        final contentLength = response.contentLength ?? 0;
        var downloaded = 0;
        
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloaded += chunk.length;
          if (contentLength > 0) {
            _downloadProgress[surah.number] = downloaded / contentLength;
          }
        }
        
        await sink.close();
        _downloadedSurahs[surah.number] = true;
        _downloadProgress[surah.number] = 1.0;
        _downloadingSurahs[surah.number] = false;
        return true;
      }
      
      _downloadingSurahs[surah.number] = false;
      return false;
    } catch (e) {
      print('Error downloading surah ${surah.number}: $e');
      _downloadingSurahs[surah.number] = false;
      return false;
    }
  }

  Future<bool> deleteSurah(int surahNumber) async {
    try {
      final dir = await _downloadDir;
      final file = File('$dir${Platform.pathSeparator}$surahNumber.mp3');
      if (await file.exists()) {
        await file.delete();
      }
      _downloadedSurahs.remove(surahNumber);
      _downloadProgress.remove(surahNumber);
      return true;
    } catch (e) {
      print('Error deleting surah $surahNumber: $e');
      return false;
    }
  }
}
