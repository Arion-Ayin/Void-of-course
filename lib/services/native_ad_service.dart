import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:void_of_course/services/ad_ids.dart';

class NativeAdService {
  static final NativeAdService _instance = NativeAdService._internal();
  factory NativeAdService() => _instance;
  NativeAdService._internal();

  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  NativeAd? get nativeAd => _nativeAd;
  bool get isAdLoaded => _isAdLoaded;

  void loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdIds.nativeAd,
      request: const AdRequest(),
      factoryId: 'listTile',
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          _nativeAd = ad as NativeAd;
          _isAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _isAdLoaded = false;
        },
      ),
    );
    _nativeAd?.load();
  }

  void dispose() {
    _nativeAd?.dispose();
    _isAdLoaded = false;
  }
}
