import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/quran_service.dart';
import '../../core/models/surah_model.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class SurahScreen extends StatelessWidget {
  const SurahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final QuranService quranService = Get.find<QuranService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cimooje'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Obx(() {
        if (quranService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (quranService.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Error loading surahs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(quranService.error!),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: quranService.loadSurahs,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (quranService.surahs.isEmpty) {
          return const Center(
            child: Text(
              'No surahs available',
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quranService.surahs.length,
          itemBuilder: (context, index) {
            final SurahModel surah = quranService.surahs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    '${surah.number}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      surah.namePulaar,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      surah.nameArabic,
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  '${surah.versesCount} verses',
                ),
                onTap: () {
                  quranService.setCurrentSurah(surah);
                  Get.toNamed(AppRoutes.surah, arguments: surah);
                },
              ),
            );
          },
        );
      }),
    );
  }
}
