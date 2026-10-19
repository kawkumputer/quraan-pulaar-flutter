import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/constants/strings.dart';
import '../../core/services/quran_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/ad_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/respectful_banner_ad.dart';

class AllSurahsScreen extends GetView<QuranService> {
  const AllSurahsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsService = Get.find<SettingsService>();

    return WillPopScope(
      onWillPop: () async {
        Get.find<AdService>().showInterstitialAd('all_surahs_screen');
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Get.find<AdService>().showInterstitialAd('all_surahs_screen');
              Get.back();
            },
          ),
          title: Text(
            S.surahs,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: false,
          actions: [
            Obx(() => settingsService.isActivated
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
                          S.activated,
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
                    tooltip: S.unlockAll,
                  ),
            ),
          ],
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: Obx(() {
                if (controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final surahs = controller.surahs;
                if (surahs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(controller.error != null ? S.loadError : S.noSurahs),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(S.retry),
                          onPressed: () => controller.loadSurahs(force: true),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (!settingsService.isActivated)
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
                                    S.freeVersion,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    S.freeSurahsBanner,
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
                              label: Text(S.activate),
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
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final surah = surahs[index];
                          final bool isLocked = controller.isLocked(surah);

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: InkWell(
                              onTap: isLocked
                                  ? () => Get.toNamed(AppRoutes.activation)
                                  : () => AppRoutes.openSurah(surah),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isLocked
                                            ? Colors.grey.shade300
                                            : Theme.of(context).primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${surah.number}',
                                          style: TextStyle(
                                            color: isLocked ? Colors.grey : Colors.white,
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
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Amiri',
                                                  color: isLocked ? Colors.grey : null,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '• ${S.versesCount(surah.versesCount)}',
                                                style: TextStyle(
                                                  color: isLocked
                                                      ? Colors.grey
                                                      : Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                surah.namePulaar,
                                                style: TextStyle(
                                                  color: isLocked
                                                      ? Colors.grey
                                                      : Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                              if (isLocked) ...[
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.lock_outline,
                                                  size: 16,
                                                  color: Colors.grey[400],
                                                ),
                                              ],
                                            ],
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
            ),
            const RespectfulBannerAd(
              screenId: 'all_surahs_screen',
              isQuranSection: false,
            ),
          ],
        ),
      ),
    );
  }
}
