import 'package:flutter/foundation.dart';

/// Centralized ad unit id manager.
/// Use `AdIds.interstitial`, `AdIds.banner`, `AdIds.nativeAd` to get
/// the appropriate id for debug (test) or release (production).
class AdIds {
  // Interstitial (splash / full-screen)
  static String get interstitial {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/4411468910' // iOS test interstitial
          : 'ca-app-pub-3940256099942544/1033173712'; // Android test interstitial
    } else {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-7332476431820224/1445902044' // iOS production interstitial
          : 'ca-app-pub-7332476431820224/2876868409'; // Android production interstitial
    }
  }

  // Banner
  static String get banner {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/2934735716' // iOS test banner
          : 'ca-app-pub-3940256099942544/6300978111'; // Android test banner
    } else {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-7332476431820224/1282250518' // iOS production banner
          : 'ca-app-pub-7332476431820224/6217062207'; // Android production banner
    }
  }

  // Native
  static String get nativeAd {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/3986693107' // iOS test native
          : 'ca-app-pub-3940256099942544/2247696110'; // Android test native
    } else {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? 'ca-app-pub-7332476431820224/4376690861' // iOS production native
          : 'ca-app-pub-7332476431820224/3843192065'; // Android production native
    }
  }
}
