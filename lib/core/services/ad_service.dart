import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdService extends GetxService {
  static AdService get to => Get.find();
  
  // Test ad unit IDs while account is pending approval
  final String _bannerAdUnitId = kDebugMode || true // Force test ads until account approved
      ? 'ca-app-pub-3940256099942544/6300978111'  // Test banner ID
      : Platform.isAndroid
          ? 'ca-app-pub-4086972652140089/5635971060'  // Android banner ID
          : 'ca-app-pub-4086972652140089/5635971060'; // Use same for iOS for now

  final String _interstitialAdUnitId = kDebugMode || true // Force test ads until account approved
      ? 'ca-app-pub-3940256099942544/1033173712'  // Test interstitial ID
      : Platform.isAndroid
          ? 'ca-app-pub-4086972652140089/7123456789'  // Replace with your Android interstitial ID
          : 'ca-app-pub-4086972652140089/7123456789'; // Replace with your iOS interstitial ID
      
  final _bannerAds = <String, Rx<BannerAd?>>{};
  final _interstitialAds = <String, Rx<InterstitialAd?>>{};
  final _lastInterstitialShow = <String, DateTime>{};
  
  // Minimum time between interstitial ads per screen (3 minutes)
  static const _minInterstitialInterval = Duration(minutes: 3);

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

  Rx<InterstitialAd?> getInterstitialAdController(String screenId) {
    return _interstitialAds.putIfAbsent(screenId, () => Rx<InterstitialAd?>(null));
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

  // Load and show interstitial ad with content filtering
  Future<void> showInterstitialAd(String screenId) async {
    // Check if enough time has passed since last show
    final lastShow = _lastInterstitialShow[screenId];
    if (lastShow != null && DateTime.now().difference(lastShow) < _minInterstitialInterval) {
      debugPrint('Skipping interstitial ad - too soon since last show');
      return;
    }

    final adController = getInterstitialAdController(screenId);
    
    final adRequest = AdRequest(
      keywords: ['education', 'books', 'learning', 'quran'],
      contentUrl: 'https://quran.com',
      nonPersonalizedAds: true,
    );

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully for screen: $screenId');
            adController.value = ad;
            
            // Show the ad and update last show time
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                debugPrint('Interstitial ad dismissed');
                ad.dispose();
                adController.value = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                debugPrint('Interstitial ad failed to show: $error');
                ad.dispose();
                adController.value = null;
              },
            );
            
            ad.show();
            _lastInterstitialShow[screenId] = DateTime.now();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load for screen $screenId: $error');
            adController.value = null;
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad for screen $screenId: $e');
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

  void disposeInterstitialAd(String screenId) {
    final adController = _interstitialAds[screenId];
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
    for (final adController in _interstitialAds.values) {
      adController.value?.dispose();
    }
    _bannerAds.clear();
    _interstitialAds.clear();
    _lastInterstitialShow.clear();
    super.onClose();
  }
}
