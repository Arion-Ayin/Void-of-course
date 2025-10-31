import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 전면 광고 및 광고 정책을 관리하는 서비스 클래스입니다.
class AdService {
  InterstitialAd? _interstitialAd;
  int _calculateClickCount = 0;
  final int _adFrequency = 7; // 광고 표시 빈도 (7번 클릭마다)

  static const _clickCountKey = 'calculateClickCount';
  static const _lastSplashAdShowTimeKey = 'lastSplashAdShowTime';

  /// 서비스 초기화 시 광고와 클릭 횟수를 로드합니다.
  Future<void> initialize() async {
    await _loadCalculateClickCount();
    _loadInterstitialAd();
  }

  /// 전면 광고를 로드합니다.
  void _loadInterstitialAd() {
    InterstitialAd.load( // 이전에 설정된 일반 전면 광고 로드
      adUnitId: 'ca-app-pub-7332476431820224/2876868409', // 실제 광고 ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
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

    if (_calculateClickCount % _adFrequency == 0 && _interstitialAd != null) {
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
    return false; // 광고가 표시되지 않음
  }

  /// 스플래시 화면에서 사용할 전면 광고를 로드하고 표시합니다.
  Future<void> loadAndShowSplashAd({
    required String adUnitId,
    required Function onAdDismissed,
    required Function onAdFailed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastAdShowTimeMillis = prefs.getInt(_lastSplashAdShowTimeKey) ?? 0;
    final currentTimeMillis = DateTime.now().millisecondsSinceEpoch;

    // 30분 (밀리초 단위)
    const thirtyMinutesInMillis = 30 * 60 * 1000;

    if (currentTimeMillis - lastAdShowTimeMillis < thirtyMinutesInMillis) {
      onAdFailed(); // 30분 이내에는 광고를 보여주지 않음
      return;
    }

    InterstitialAd? splashAd;
    await InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) async {
          // 광고가 성공적으로 로드되면, 현재 시간을 저장
          await prefs.setInt(_lastSplashAdShowTimeKey, currentTimeMillis);
          splashAd = ad;
          splashAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              onAdDismissed(); // 광고가 닫히면 콜백 실행
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              onAdFailed(); // 광고 표시에 실패하면 콜백 실행
              ad.dispose();
            },
          );
          splashAd!.show(); // 광고 표시
        },
        onAdFailedToLoad: (error) {
          onAdFailed(); // 광고 로드에 실패하면 콜백 실행
        },
      ),
    );
  }

  Future<void> _loadCalculateClickCount() async {
    final prefs = await SharedPreferences.getInstance();
    _calculateClickCount = prefs.getInt(_clickCountKey) ?? 0;
  }

  Future<void> _saveCalculateClickCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_clickCountKey, _calculateClickCount);
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}