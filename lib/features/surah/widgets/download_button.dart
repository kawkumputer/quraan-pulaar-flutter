import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/audio_controller.dart';

class DownloadButton extends StatelessWidget {
  final int surahNumber;
  final AudioController controller;

  const DownloadButton({
    super.key,
    required this.surahNumber,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (controller.isSurahDownloaded(surahNumber)) {
      return IconButton(
        icon: const Icon(Icons.download_done),
        onPressed: () {
          Get.dialog(
            AlertDialog(
              title: const Text('Momtu Simoore'),
              content: const Text('Aɗa yiɗi momtude simoore nde?'),
              actions: [
                TextButton(
                  child: const Text('Alaa'),
                  onPressed: () => Get.back(),
                ),
                TextButton(
                  child: const Text('Eyy'),
                  onPressed: () async {
                    await controller.deleteSurah(surahNumber);
                    Get.back();
                  },
                ),
              ],
            ),
          );
        },
      );
    } else if (controller.isSurahDownloading(surahNumber)) {
      final progress = controller.getSurahDownloadProgress(surahNumber);
      return Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 2,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            Center(
              child: Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.download_outlined),
        onPressed: () async {
          final success = await controller.downloadSurah(surahNumber);
          if (!success) {
            Get.snackbar(
              'Juumre',
              'Roŋki aawde simoore nde',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Get.theme.colorScheme.error,
              colorText: Get.theme.colorScheme.onError,
            );
          }
        },
      );
    }
  }
}
