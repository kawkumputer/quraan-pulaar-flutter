import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'settings_service.dart';

class AudioDownloadService extends GetxService {
  final downloadProgress = <int, double>{}.obs;
  final downloadedSurahs = <int>{}.obs;
  final _settingsService = Get.find<SettingsService>();

  @override
  void onInit() {
    super.onInit();
    _loadDownloadedSurahs();
  }

  Future<void> _loadDownloadedSurahs() async {
    try {
      final dir = await _getAudioDirectory();
      final files = dir.listSync();
      
      for (var file in files) {
        if (file is File && file.path.endsWith('.mp3')) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          final surahNumber = int.tryParse(fileName.split('.').first);
          if (surahNumber != null) {
            // Only add to downloaded list if it's within activation limits
            if (_settingsService.isActivated || surahNumber <= 4) {
              downloadedSurahs.add(surahNumber);
            } else {
              // Delete files that shouldn't be accessible
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Error loading downloaded surahs: $e');
    }
  }

  Future<String?> getDownloadedAudioPath(int surahNumber) async {
    try {
      // Check activation status
      if (!_settingsService.isActivated && surahNumber > 4) {
        return null;
      }

      final dir = await _getAudioDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$surahNumber.mp3');
      return file.existsSync() ? file.path : null;
    } catch (e) {
      print('Error getting downloaded audio path: $e');
      return null;
    }
  }

  Future<void> downloadSurah(int surahNumber, String url) async {
    if (!_settingsService.isActivated && surahNumber > 4) {
      throw Exception('Yamiro ngam aawde simoore nde');
    }

    try {
      final dir = await _getAudioDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$surahNumber.mp3');
      
      // If file already exists, no need to download again
      if (file.existsSync()) {
        downloadedSurahs.add(surahNumber);
        downloadProgress[surahNumber] = 1.0;
        downloadProgress.refresh();
        return;
      }

      final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final contentLength = response.contentLength ?? 0;
      
      if (contentLength == 0) {
        throw Exception('Alaa simoore nde');
      }

      var receivedBytes = 0;
      final sink = file.openWrite();
      
      downloadProgress[surahNumber] = 0.0;
      downloadProgress.refresh();

      await response.stream.listen(
        (List<int> chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          downloadProgress[surahNumber] = receivedBytes / contentLength;
          downloadProgress.refresh();
        },
        onDone: () async {
          await sink.close();
          downloadedSurahs.add(surahNumber);
          downloadProgress[surahNumber] = 1.0;
          downloadProgress.refresh();
        },
        onError: (error) {
          sink.close();
          file.deleteSync();
          downloadProgress.remove(surahNumber);
          downloadProgress.refresh();
          throw Exception('Roŋki aawde simoore nde');
        },
        cancelOnError: true,
      ).asFuture(); // Convert the StreamSubscription to a Future
    } catch (e) {
      downloadProgress.remove(surahNumber);
      downloadProgress.refresh();
      print('Error downloading surah: $e');
      rethrow;
    }
  }

  Future<Directory> _getAudioDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${appDir.path}${Platform.pathSeparator}audio');
    if (!audioDir.existsSync()) {
      audioDir.createSync();
    }
    return audioDir;
  }

  Future<void> deleteSurah(int surahNumber) async {
    try {
      final dir = await _getAudioDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}$surahNumber.mp3');
      
      if (file.existsSync()) {
        await file.delete();
        downloadedSurahs.remove(surahNumber);
        downloadProgress.remove(surahNumber);
        downloadProgress.refresh();
      }
    } catch (e) {
      print('Error deleting surah: $e');
      rethrow;
    }
  }

  Future<void> cleanupInvalidDownloads() async {
    try {
      if (!_settingsService.isActivated) {
        final dir = await _getAudioDirectory();
        final files = dir.listSync();
        
        for (var file in files) {
          if (file is File && file.path.endsWith('.mp3')) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            final surahNumber = int.tryParse(fileName.split('.').first);
            if (surahNumber != null && surahNumber > 4) {
              await file.delete();
              downloadedSurahs.remove(surahNumber);
              downloadProgress.remove(surahNumber);
            }
          }
        }
        downloadProgress.refresh();
      }
    } catch (e) {
      print('Error cleaning up invalid downloads: $e');
    }
  }
}
