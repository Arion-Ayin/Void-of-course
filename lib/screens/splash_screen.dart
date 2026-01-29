import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:void_of_course/services/ad_service.dart';
import 'package:void_of_course/main.dart';
import 'package:void_of_course/services/astro_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _adTriggered = false;

  void didChangeDependencies() {
    super.didChangeDependencies();
    // astroState가 이미 초기화되었는지 확인
    final astroState = Provider.of<AstroState>(context, listen: false);
    if (astroState.isInitialized && !_adTriggered) {
      _triggerAdShow();
    }
  }

  void _navigateToMainScreen() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => MainAppScreen()));
  }

  Future<void> _showAdAndNavigate() async {
    if (kDebugMode) {
      _navigateToMainScreen();
    } else {
      final adService = AdService();
      await adService.showSplashAd(
        onAdDismissed: _navigateToMainScreen,
        onAdFailed: _navigateToMainScreen,
      );
    }
  }

  void _triggerAdShow() {
    if (_adTriggered) return;
    _adTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAdAndNavigate();
    });
  }

  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Android 15+ Edge-to-Edge를 위한 시스템 UI 설정
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // 스플래시는 보통 어두운 배경
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        // Edge-to-Edge를 위해 배경색을 body 전체에 적용
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: Consumer<AstroState>(
          builder: (context, astroState, child) {
            if (astroState.isInitialized) {
              _triggerAdShow();
            }

            // 스플래시 화면은 전체 화면을 사용하므로 SafeArea 제거
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: Theme.of(context).colorScheme.primary,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Loading...',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}