import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import 'package:get/get.dart';

class RespectfulBannerAd extends StatefulWidget {
  // Only show in non-sacred sections
  final bool isQuranSection;
  final bool isAudioPlaying;
  final String screenId;
  
  const RespectfulBannerAd({
    Key? key,
    this.isQuranSection = false,
    this.isAudioPlaying = false,
    required this.screenId,
  }) : super(key: key);

  @override
  State<RespectfulBannerAd> createState() => _RespectfulBannerAdState();
}

class _RespectfulBannerAdState extends State<RespectfulBannerAd> {
  final adService = Get.find<AdService>();
  late final bannerAdController = adService.getBannerAdController(widget.screenId);

  @override
  void initState() {
    super.initState();
    // Only load ads in appropriate sections
    if (!widget.isQuranSection && !widget.isAudioPlaying) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    await adService.loadBannerAd(widget.screenId);
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads during Quran reading or audio playback
    if (widget.isQuranSection || widget.isAudioPlaying) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final currentAd = bannerAdController.value;
      if (currentAd == null) {
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        width: currentAd.size.width.toDouble(),
        height: currentAd.size.height.toDouble(),
        child: AdWidget(ad: currentAd),
      );
    });
  }

  @override
  void dispose() {
    adService.disposeBannerAd(widget.screenId);
    super.dispose();
  }
}
