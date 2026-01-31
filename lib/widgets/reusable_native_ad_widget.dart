
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:void_of_course/services/ad_ids.dart';

class ReusableNativeAdWidget extends StatefulWidget {
  const ReusableNativeAdWidget({super.key});

  @override
  State<ReusableNativeAdWidget> createState() => _ReusableNativeAdWidgetState();
}

class _ReusableNativeAdWidgetState extends State<ReusableNativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  // Centralized native ad unit id
  final String _adUnitId = AdIds.nativeAd;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      factoryId: 'listTile', // This must match the factory implemented in the native code.
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
    _nativeAd?.load();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _nativeAd != null) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320, // Ad-Loader says minimum width is 320.
          minHeight: 100, // Minimum height for this template.
          maxWidth: 400,
          maxHeight: 150,
        ),
        child: AdWidget(ad: _nativeAd!),
      );
    } else {
      return const SizedBox.shrink(); // Return an empty box if the ad is not loaded.
    }
  }
}
