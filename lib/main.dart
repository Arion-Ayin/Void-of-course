import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'screens/home_screen.dart';
import 'screens/Developer Notes_screen.dart';
import 'screens/setting_screen.dart';
import 'services/astro_state.dart';
import 'themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_of_course/screens/splash_screen.dart';
import 'package:void_of_course/services/locale_provider.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:void_of_course/widgets/exit_confirmation_dialog.dart';
import 'package:void_of_course/services/ad_service.dart';
import 'package:flutter/services.dart';
import 'package:void_of_course/services/background_service.dart';

void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요.
  WidgetsFlutterBinding.ensureInitialized();

  //백그라운드 서비스 세팅 대기함수
  await initializeBackgroundService();

  // Google Mobile Ads SDK와 AdService를 초기화해요.
  if (Platform.isAndroid || Platform.isIOS) {
    await MobileAds.instance.initialize();
    await AdService().initialize();
  }

  //앱의 실행
  runApp(
    MultiProvider(
      providers: [
        //astro_state.dart의 AstroState를 초기화(initialize)하고 Provider로 등록
        ChangeNotifierProvider(create: (context) => AstroState()..initialize()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 우리 앱의 가장 기본적인 위젯이에요.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 앱 화면 보여주기
  @override
  Widget build(BuildContext context) {
    // 테마를 관리하고 앱의 기본 설정을 하는 위젯이에요.
    return ThemeProvider(
      initTheme:
          Theme.of(context).brightness == Brightness.dark
              ? Themes.darkTheme
              : Themes.lightTheme,
      builder: (context, myTheme) {
        final localeProvider = Provider.of<LocaleProvider>(context);
        return MaterialApp(
          title: 'Void of Course',
          debugShowCheckedModeBanner: false,
          theme: myTheme,
          home: const SplashScreen(),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,

          // ▼▼▼ [수정 1] 글자 크기 고정 설정 (UI 깨짐 방지) ▼▼▼
          builder: (context, child) {
            return MediaQuery(
              // 사용자가 시스템 글자 크기를 키워도 앱 내에서는 1.0배로 고정
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // ▲▲▲ 여기까지 ▲▲▲
        );
      },
    );
  }
}

// 앱의 메인 화면 (하단 내비게이션 바가 있는 화면)
class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialLocale =
          Provider.of<LocaleProvider>(context, listen: false).locale;
      if (initialLocale != null) {
        Provider.of<AstroState>(
          context,
          listen: false,
        ).updateLocale(initialLocale.languageCode);
      }
    });
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      print('Error checking for update: $e');
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => const ExitConfirmationDialog(),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    // 현재 테마가 다크 모드인지 확인해요.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<AstroState>(
      builder: (context, astroState, child) {
        if (!astroState.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (astroState.lastError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '오류가 발생하여 앱을 실행할 수 없습니다.\n\n${astroState.lastError}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          );
        }

        return WillPopScope(
          onWillPop: _onWillPop,
          // ▼▼▼ [수정됨] 상태바 아이콘 색상 제어 코드 추가 ▼▼▼
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              // 상태바 배경색을 투명하게 해서 앱 배경색이 보이게 함
              statusBarColor: Colors.transparent,
              // 다크 모드면 아이콘을 밝게(흰색), 라이트 모드면 어둡게(검은색) 설정
              statusBarIconBrightness:
                  isDarkMode ? Brightness.light : Brightness.dark,
              // iOS를 위한 설정
              statusBarBrightness:
                  isDarkMode ? Brightness.dark : Brightness.light,
            ),
            child: Scaffold(
              // SafeArea는 유지 (화면 가림 방지)
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: _buildScreens(),
                      ),
                    ),
                    const BannerAdWidget(),
                  ],
                ),
              ),
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color:
                          isDarkMode
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor:
                      isDarkMode ? Colors.blue[300] : Colors.blue[600],
                  unselectedItemColor:
                      isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  type: BottomNavigationBarType.fixed,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home),
                      label: AppLocalizations.of(context)!.home,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.settings),
                      label: AppLocalizations.of(context)!.settings,
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.description),
                      label: AppLocalizations.of(context)!.infoScreenTitle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ▲▲▲ 여기까지 ▲▲▲
        );
      },
    );
  }

  List<Widget> _buildScreens() {
    return [HomeScreen(), const SettingScreen(), const InfoScreen()];
  }
}

// 배너 광고 위젯
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  final String _adUnitId = 'ca-app-pub-7332476431820224/6217062207';

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          print('BannerAd failed to load: $err');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
