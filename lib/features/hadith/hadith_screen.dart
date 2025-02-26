import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/controllers/audio_controller.dart';
import '../../core/services/hadith_service.dart';
import 'models/hadith.dart';
import 'widgets/hadith_card.dart';

class HadithController extends GetxController {
  final HadithService _hadithService = Get.find<HadithService>();
  final RxList<Hadith> hadiths = <Hadith>[].obs;
  final RxBool isLoading = true.obs;

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
          title: const Text('Hadiths'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final audioController = Get.find<AudioController>();
              await audioController.stopPlaying();
              Get.back();
            },
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (controller.hadiths.isEmpty) {
            return const Center(
              child: Text('No hadiths available'),
            );
          }

          return ListView.builder(
            itemCount: controller.hadiths.length,
            itemBuilder: (context, index) {
              final hadith = controller.hadiths[index];
              return HadithCard(hadith: hadith);
            },
          );
        }),
      ),
    );
  }
}
