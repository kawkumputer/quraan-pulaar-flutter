import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdService extends GetxService {
  static AdService get to => Get.find();
  
  // Production ad unit ID
  final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-4086972652140089/5635971060'  // Android banner ID
      : 'ca-app-pub-4086972652140089/5635971060'; // Use same for iOS for now
      
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

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
      ),
    );
  }

  // Load banner ad with content filtering
  Future<BannerAd?> loadBannerAd() async {
    final adRequest = AdRequest(
      // Additional content filtering
      keywords: ['education', 'books', 'learning', 'quran'],
      contentUrl: 'https://quran.com', // Helps AdMob understand context
      nonPersonalizedAds: true, // Prefer non-personalized ads
    );

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isAdLoaded = true;
          debugPrint('Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          _bannerAd = null;
          _isAdLoaded = false;
        },
        // Monitor ad content
        onAdOpened: (ad) {
          debugPrint('Ad opened - checking content');
        },
        onAdClosed: (ad) {
          debugPrint('Ad closed');
        },
      ),
    );

    try {
      await _bannerAd?.load();
      return _bannerAd;
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _bannerAd?.dispose();
      _bannerAd = null;
      return null;
    }
  }

  BannerAd? get bannerAd => _isAdLoaded ? _bannerAd : null;

  @override
  void onClose() {
    _bannerAd?.dispose();
    super.onClose();
  }
}
