import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/quran_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/models/surah_model.dart';

class AllSurahsScreen extends GetView<QuranService> {
  const AllSurahsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text('All Surahs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open),
            onPressed: () => Get.toNamed(AppRoutes.activation),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return Center(child: Text('Error: ${controller.error}'));
        }

        final surahs = controller.surahs;
        if (surahs.isEmpty) {
          return const Center(child: Text('No surahs found'));
        }

        return Column(
          children: [
            if (!settingsService.isActivated)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.amber.shade100,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only the first three surahs are available. Activate the app to access all surahs.',
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.activation),
                      child: const Text('Activate'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: surahs.length,
                itemBuilder: (context, index) {
                  final surah = surahs[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        controller.setCurrentSurah(surah);
                        Get.toNamed(AppRoutes.surah, arguments: surah);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${surah.number}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        surah.nameArabic,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Amiri',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${surah.versesCount} verses',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    surah.namePulaar,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
