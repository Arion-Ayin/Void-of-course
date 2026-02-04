import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:void_of_course/services/ad_ids.dart';

/// 전면 광고 및 광고 정책을 관리하는 서비스 클래스입니다.
class AdService {
  static final AdService _instance = AdService._internal();

  factory AdService() {
    return _instance;
  }

  AdService._internal();

  bool _isInitialized = false;
  SharedPreferences? _prefs; // 캐시된 SharedPreferences

  InterstitialAd? _interstitialAd;
  int _calculateClickCount = 0;
  final int _adFrequency = 10; // 광고 표시 빈도 (10번 클릭마다)

  static const _clickCountKey = 'calculateClickCount';
  static const _lastSplashAdShowTimeKey = 'lastSplashAdShowTime';

  /// 서비스 초기화 시 광고와 클릭 횟수를 로드합니다.
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    await _loadCalculateClickCount();
    print('AdService initialized. Click count: $_calculateClickCount');
    if (Platform.isAndroid || Platform.isIOS) {
      _loadInterstitialAd();
    }
    _isInitialized = true;
  }

  /// 전면 광고를 로드합니다.
  void _loadInterstitialAd() {
    InterstitialAd.load(
      // 이전에 설정된 일반 전면 광고 로드 (centralized AdIds)
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded.');
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _interstitialAd?.dispose();
          _interstitialAd = null;
        },
      ),
    );
  }

  /// 광고를 표시할지 결정하고, 필요 시 광고를 보여줍니다.
  /// 광고가 표시되면 true, 아니면 false를 반환합니다.
  Future<bool> showAdIfNeeded(Function onAdDismissed) async {
    _calculateClickCount++;
    await _saveCalculateClickCount();
    print('showAdIfNeeded called. Click count: $_calculateClickCount');

    if ((Platform.isAndroid || Platform.isIOS) &&
        _calculateClickCount % _adFrequency == 0 &&
        _interstitialAd != null) {
      print('Showing interstitial ad.');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onAdDismissed();
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          onAdDismissed();
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      return true; // 광고가 표시됨
    }
    print('Interstitial ad not shown.');
    return false; // 광고가 표시되지 않음
  }

  /// 스플래시 화면에 미리 로드된 전면 광고를 표시합니다.
  Future<void> showSplashAd({
    required Function onAdDismissed,
    required Function onAdFailed,
  }) async {
    final lastAdShowTimeMillis = _prefs?.getInt(_lastSplashAdShowTimeKey) ?? 0;
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;

    // 30분 (밀리초 단위)
    const thirtyMinutesInMillis = 30 * 60 * 1000;

    // 새로고침 10번 이상 누른 경우 30분 규칙을 무시하고 광고 표시
    final shouldShowAdByClickCount = _calculateClickCount >= _adFrequency;

    // 30분 이내에 광고를 본 경우, 새로고침 횟수를 확인합니다.
    if (currentTimeMillis - lastAdShowTimeMillis < thirtyMinutesInMillis) {
      if (!shouldShowAdByClickCount) {
        print("스플래시 광고: 마지막 광고 표시 후 30분이 지나지 않았습니다.");
        onAdFailed();
        return;
      } else {
        print("스플래시 광고: 새로고침 $_calculateClickCount회로 30분 규칙을 무시하고 광고를 표시합니다.");
      }
    }

    // 미리 로드된 광고가 있는지 확인합니다.
    if ((Platform.isAndroid || Platform.isIOS) && _interstitialAd != null) {
      print("미리 로드된 스플래시 광고를 표시합니다.");
      // 광고 표시 시간을 지금으로 기록합니다.
      await _prefs?.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);

      // 새로고침 횟수로 인해 광고를 표시한 경우 카운트를 리셋합니다.
      if (shouldShowAdByClickCount) {
        _calculateClickCount = 0;
        await _saveCalculateClickCount();
        print("스플래시 광고 표시로 인해 클릭 카운트를 리셋했습니다.");
      }

      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          onAdDismissed(); // 광고가 닫히면 콜백 실행
          ad.dispose();
          _loadInterstitialAd(); // 다음 광고를 미리 로드합니다.
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print("스플래시 광고 표시에 실패했습니다: $error");
          onAdFailed(); // 광고 표시에 실패하면 콜백 실행
          ad.dispose();
          _loadInterstitialAd(); // 다음 광고를 미리 로드합니다.
        },
      );
      await _interstitialAd!.show();
    } else {
      // 광고가 아직 로드되지 않은 경우, 바로 onAdFailed를 호출합니다.
      print("스플래시 광고: 미리 로드된 광고가 없습니다.");
      onAdFailed();
    }
  }

  /// 주어진 광고 단위 ID로 스플래시 전면광고를 표시합니다.
  /// 미리 로드된 광고가 있으면 즉시 표시하고, 없으면 새로 로드합니다.
  /// `timeout` 내에 로드되지 않으면 `onAdFailed`가 호출됩니다.
  Future<void> loadAndShowSplashAd({
    required String adUnitId,
    required Function onAdDismissed,
    required Function onAdFailed,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    // 디버그 모드에서는 스플래시 광고를 즉시 건너뜁니다.
    if (kDebugMode) {
      print('디버그 모드이므로 스플래시 광고를 건너뜁니다.');
      onAdFailed();
      return;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      onAdFailed();
      return;
    }

    final lastAdShowTimeMillis = _prefs?.getInt(_lastSplashAdShowTimeKey) ?? 0;
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;
    const thirtyMinutesInMillis = 30 * 60 * 1000;

    final shouldShowAdByClickCount = _calculateClickCount >= _adFrequency;

    if (currentTimeMillis - lastAdShowTimeMillis < thirtyMinutesInMillis &&
        !shouldShowAdByClickCount) {
      print('스플래시 광고 로드: 30분 규칙 때문에 표시하지 않습니다.');
      onAdFailed();
      return;
    }

    // 미리 로드된 광고가 있으면 즉시 표시
    if (_interstitialAd != null) {
      print('미리 로드된 스플래시 광고를 즉시 표시합니다.');
      try {
        await _prefs?.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);
      } catch (_) {}

      if (shouldShowAdByClickCount) {
        _calculateClickCount = 0;
        await _saveCalculateClickCount();
        print('클릭 카운트를 리셋합니다.');
      }

      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          try {
            ad.dispose();
          } catch (_) {}
          _interstitialAd = null;
          _loadInterstitialAd();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          try {
            ad.dispose();
          } catch (_) {}
          _interstitialAd = null;
          _loadInterstitialAd();
          onAdFailed();
        },
      );

      await _interstitialAd!.show();
      return;
    }

    // 미리 로드된 광고가 없으면 새로 로드 시도
    print('미리 로드된 광고가 없어 새로 로드합니다.');
    final completer = Completer<void>();
    Timer? timer;
    InterstitialAd? loadedAd;

    void cleanupAndFail([String? reason]) {
      timer?.cancel();
      if (loadedAd != null) {
        try {
          loadedAd!.dispose();
        } catch (_) {}
        loadedAd = null;
      }
      if (!completer.isCompleted) {
        completer.complete();
      }
      onAdFailed();
      if (reason != null) print('loadAndShowSplashAd failed: $reason');
    }

    timer = Timer(timeout, () {
      cleanupAndFail('timeout');
    });

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
          timer?.cancel();
          loadedAd = ad;
          try {
            await _prefs?.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);
          } catch (_) {}

          if (shouldShowAdByClickCount) {
            _calculateClickCount = 0;
            await _saveCalculateClickCount();
            print('클릭 카운트를 리셋합니다.');
          }

          loadedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              try {
                ad.dispose();
              } catch (_) {}
              _loadInterstitialAd();
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              try {
                ad.dispose();
              } catch (_) {}
              _loadInterstitialAd();
              onAdFailed();
            },
          );

          await loadedAd!.show();
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (error) {
          cleanupAndFail(error.message);
        },
      ),
    );

    return completer.future;
  }

  Future<void> _loadCalculateClickCount() async {
    _calculateClickCount = _prefs?.getInt(_clickCountKey) ?? 0;
  }

  Future<void> _saveCalculateClickCount() async {
    await _prefs?.setInt(_clickCountKey, _calculateClickCount);
  }
}
