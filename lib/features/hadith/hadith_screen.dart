import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/audio_controller.dart';
import '../../core/services/hadith_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/routes/app_routes.dart';
import 'models/hadith.dart';
import 'widgets/hadith_card.dart';

class HadithController extends GetxController {
  final HadithService _hadithService = Get.find<HadithService>();
  final SettingsService _settingsService = Get.find<SettingsService>();
  final RxList<Hadith> hadiths = <Hadith>[].obs;
  final RxBool isLoading = true.obs;

  bool get isActivated => _settingsService.isActivated;

  @override
  void onInit() {
    super.onInit();
    loadHadiths();
  }

  Future<void> loadHadiths() async {
    try {
      isLoading.value = true;
      final hadithsList = await _hadithService.getAllHadiths();
      hadiths.value = hadithsList;
    } finally {
      isLoading.value = false;
    }
  }
}

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HadithController());

    return WillPopScope(
      onWillPop: () async {
        final audioController = Get.find<AudioController>();
        await audioController.stopPlaying();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Hadiisaaji',
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final audioController = Get.find<AudioController>();
              await audioController.stopPlaying();
              Get.back();
            },
          ),
          actions: [
            Obx(() => controller.isActivated
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Huuɓnaama',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.lock_outline),
                    onPressed: () => Get.toNamed(AppRoutes.activation),
                    tooltip: 'Huuɓnu',
                  ),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.hadiths.isEmpty) {
            return const Center(
              child: Text('Alaa hadiisaaji goodɗi'),
            );
          }

          return Column(
            children: [
              if (!controller.isActivated)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: Colors.amber.shade50,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline,
                          color: Colors.amber.shade900,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yamre Ɓolnde',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Njogiɗaa tan ko njangtuuji (Hadisaaji) tati. Huuɓnu ngam keɓa njangtuuji nulaaɗo ɗii kala.',
                              style: TextStyle(
                                color: Colors.amber.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open, size: 18),
                        label: const Text('Huuɓnu'),
                        onPressed: () => Get.toNamed(AppRoutes.activation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: controller.hadiths.length,
                  itemBuilder: (context, index) {
                    final hadith = controller.hadiths[index];
                    final bool isLocked = !controller.isActivated && index >= 3;

                    if (isLocked) {
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          title: Text(
                            'Hadiisa ${hadith.id}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          subtitle: Text(
                            'Loowdi Kuuɓntundi',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          onTap: () => Get.toNamed(AppRoutes.activation),
                        ),
                      );
                    }

                    return HadithCard(hadith: hadith);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
