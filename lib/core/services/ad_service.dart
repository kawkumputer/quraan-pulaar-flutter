import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';

class AdService extends GetxService {
  static AdService get to => Get.find();

  final _bannerAds = <String, Rx<BannerAd?>>{};
  final _interstitialAds = <String, Rx<InterstitialAd?>>{};

  Rx<BannerAd?> getBannerAdController(String screenId) {
    return _bannerAds.putIfAbsent(screenId, () => Rx<BannerAd?>(null));
  }

  Rx<InterstitialAd?> getInterstitialAdController(String screenId) {
    return _interstitialAds.putIfAbsent(screenId, () => Rx<InterstitialAd?>(null));
  }

  // Ads are disabled app-wide: these are no-ops so callers throughout the
  // app keep working, but no ad ever loads and the SDK never initializes.
  Future<void> loadBannerAd(String screenId) async {}

  Future<void> showInterstitialAd(String screenId) async {}

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
    super.onClose();
  }
}
