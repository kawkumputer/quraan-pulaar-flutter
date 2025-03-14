import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import 'package:get/get.dart';

class RespectfulBannerAd extends StatefulWidget {
  // Only show in non-sacred sections
  final bool isQuranSection;
  final bool isAudioPlaying;
  
  const RespectfulBannerAd({
    Key? key,
    this.isQuranSection = false,
    this.isAudioPlaying = false,
  }) : super(key: key);

  @override
  State<RespectfulBannerAd> createState() => _RespectfulBannerAdState();
}

class _RespectfulBannerAdState extends State<RespectfulBannerAd> {
  final adService = Get.find<AdService>();
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    // Only load ads in appropriate sections
    if (!widget.isQuranSection && !widget.isAudioPlaying) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    final ad = await adService.loadBannerAd();
    if (mounted) {
      setState(() => _bannerAd = ad);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show ads during Quran reading or audio playback
    if (widget.isQuranSection || widget.isAudioPlaying) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      if (!adService.isAdLoaded || _bannerAd == null) {
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
