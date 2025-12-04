import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    return Scaffold(
      body: Consumer<AstroState>(
        builder: (context, astroState, child) {
          if (astroState.isInitialized) {
            _triggerAdShow();
          }

          return SafeArea(
            child: Container(
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
            ),
          );
        },
      ),
    );
  }
}
