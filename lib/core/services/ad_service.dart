import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdService extends GetxService {
  static AdService get to => Get.find();
  
  // Test ad unit ID while account is pending approval
  final String _bannerAdUnitId = kDebugMode || true // Force test ads until account approved
      ? 'ca-app-pub-3940256099942544/6300978111'  // Test banner ID
      : Platform.isAndroid
          ? 'ca-app-pub-4086972652140089/5635971060'  // Android banner ID
          : 'ca-app-pub-4086972652140089/5635971060'; // Use same for iOS for now
      
  final _bannerAds = <String, Rx<BannerAd?>>{};

  @override
  void onInit() {
    super.onInit();
    _initGoogleMobileAds();
  }

  Future<void> _initGoogleMobileAds() async {
    await MobileAds.instance.initialize();
    
    // Set up strict content filtering
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.yes,
        testDeviceIds: ['2F6E669A1C7C8E7F1D2FF5E8AFC9C4A4'],
      ),
    );
  }

  Rx<BannerAd?> getBannerAdController(String screenId) {
    return _bannerAds.putIfAbsent(screenId, () => Rx<BannerAd?>(null));
  }

  // Load banner ad with content filtering
  Future<void> loadBannerAd(String screenId) async {
    final adController = getBannerAdController(screenId);
    
    // Return if ad already loaded
    if (adController.value != null) {
      return;
    }

    final adRequest = AdRequest(
      keywords: ['education', 'books', 'learning', 'quran'],
      contentUrl: 'https://quran.com',
      nonPersonalizedAds: true,
    );

    final bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded successfully for screen: $screenId');
          adController.value = ad as BannerAd;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load for screen $screenId: $error');
          ad.dispose();
          adController.value = null;
        },
        onAdOpened: (ad) {
          debugPrint('Ad opened - checking content');
        },
        onAdClosed: (ad) {
          debugPrint('Ad closed');
        },
      ),
    );

    try {
      await bannerAd.load();
    } catch (e) {
      debugPrint('Error loading banner ad for screen $screenId: $e');
      bannerAd.dispose();
      adController.value = null;
    }
  }

  void disposeBannerAd(String screenId) {
    final adController = _bannerAds[screenId];
    if (adController != null) {
      adController.value?.dispose();
      adController.value = null;
    }
  }

  @override
  void onClose() {
    for (final adController in _bannerAds.values) {
      adController.value?.dispose();
    }
    _bannerAds.clear();
    super.onClose();
  }
}
