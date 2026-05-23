import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'screens/calendar_screen.dart';
import 'screens/home_screen.dart';
import 'screens/developer_notes_screen.dart';
import 'screens/setting_screen.dart';
import 'services/astro_state.dart';
import 'services/timezone_provider.dart';
import 'themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:void_of_course/screens/splash_screen.dart';
import 'package:void_of_course/services/locale_provider.dart';
import 'package:void_of_course/l10n/app_localizations.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:void_of_course/widgets/exit_confirmation_dialog.dart';
import 'package:void_of_course/services/ad_service.dart';
import 'package:void_of_course/services/ad_ids.dart';
import 'package:flutter/services.dart';
import 'package:void_of_course/services/background_service.dart';
import 'package:void_of_course/services/native_ad_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:home_widget/home_widget.dart';
import 'package:void_of_course/services/calendar_voc_cache.dart';
import 'package:void_of_course/services/widget_service.dart';
import 'package:void_of_course/services/app_analytics.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

Future<void> _initWithTimeout(
  String label,
  Future<void> Function() action, {
  Duration timeout = const Duration(seconds: 6),
}) async {
  try {
    await action().timeout(timeout);
  } catch (e) {
    developer.log('$label skipped or timed out: $e', name: 'Main');
  }
}

void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요.
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await _initWithTimeout(
      'AndroidAlarmManager',
      AndroidAlarmManager.initialize,
      timeout: const Duration(seconds: 3),
    );
  }

  // Edge-to-Edge 모드 활성화 (Android 15+ 권장)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Firebase·백그라운드는 서로 독립 → 병렬 초기화로 runApp 전 대기 시간 단축
  await Future.wait([
    _initWithTimeout('Firebase', () async {
      try {
        await Firebase.initializeApp();
      } catch (e) {
        developer.log('Firebase init failed (ignored): $e', name: 'Main');
      }
    }, timeout: const Duration(seconds: 5)),
    _initWithTimeout('BackgroundService', () async {
      try {
        await initializeBackgroundService();
      } catch (e) {
        developer.log(
          'Background service init failed (ignored): $e',
          name: 'Main',
        );
      }
    }, timeout: const Duration(seconds: 5)),
  ]);

  // Google Mobile Ads — 스플래시 전면광고용, 네이티브 광고 로드는 runApp 이후로 미룸
  if (Platform.isAndroid || Platform.isIOS) {
    await _initWithTimeout('AdMob', () async {
      try {
        await MobileAds.instance.initialize();
        await AdService().initialize();
      } catch (e) {
        developer.log('AdMob init failed (ignored): $e', name: 'Main');
      }
    }, timeout: const Duration(seconds: 5));
    NativeAdService().loadAd();
  }

  //앱의 실행
  runApp(
    MultiProvider(
      providers: [
        //astro_state.dart의 AstroState를 초기화(initialize)하고 Provider로 등록
        ChangeNotifierProvider(create: (context) => AstroState()..initialize()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
        ChangeNotifierProvider(create: (context) => TimezoneProvider()),
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
  State<MainAppScreen> createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLaunchAnalytics();
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
    _checkWidgetStatus();
  }

  void _syncLaunchAnalytics() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    AppAnalytics.setDarkModeEnabled(isDark);

    final locale =
        Provider.of<LocaleProvider>(context, listen: false).locale;
    if (locale != null) {
      AppAnalytics.setLanguage(locale.languageCode);
    }
  }

  Future<void> _checkWidgetStatus() async {
    try {
      final installedWidgets = await HomeWidget.getInstalledWidgets();
      final hasWidget = installedWidgets.isNotEmpty;
      await FirebaseAnalytics.instance.setUserProperty(
        name: 'has_home_widget',
        value: hasWidget.toString(),
      );
      if (!mounted) return;
      await Provider.of<AstroState>(
        context,
        listen: false,
      ).syncHomeWidgetFromInstallStatus(hasWidget);
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking widget status: $e', name: 'Main');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _syncLaunchAnalytics();
      _checkWidgetStatus();
      Provider.of<AstroState>(context, listen: false).ensureServiceRunning();
      WidgetService.refreshFromPrefs();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      AdService().onAppPaused();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      if (kDebugMode) {
        developer.log('Error checking for update: $e', name: 'Main');
      }
    }
  }

  void _onTabTapped(int index) {
    if (_selectedIndex != index) {
      String? eventName;
      switch (index) {
        case 0:
          eventName = 'click_home_tab';
          break;
        case 1:
          eventName = 'click_calendar_tab';
          CalendarVocCache.instance.preloadAroundSilent(DateTime.now(), radius: 2);
          break;
        case 2:
          eventName = 'click_settings_tab';
          break;
        case 3:
          eventName = 'click_info_tab';
          break;
      }

      if (eventName != null) {
        FirebaseAnalytics.instance.logEvent(name: eventName);
      }

      switch (index) {
        case 1:
          AppAnalytics.logScreenView('calendar');
          break;
        case 3:
          AppAnalytics.logScreenView('developer_notes');
          break;
      }

      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 테마가 다크 모드인지 확인해요.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Selector를 사용해서 초기화 상태만 확인 (불필요한 rebuild 방지)
    return Selector<AstroState, ({bool isInitialized, String? lastError})>(
      selector: (_, state) => (isInitialized: state.isInitialized, lastError: state.lastError),
      builder: (context, state, child) {
        if (!state.isInitialized) {
          if (state.lastError != null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '오류가 발생하여 앱을 실행할 수 없습니다.\n\n${state.lastError}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.lastError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '오류가 발생하여 앱을 실행할 수 없습니다.\n\n${state.lastError}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          );
        }

        // 초기화 완료 후에는 child를 반환 (AstroState 변경에 반응하지 않음)
        return child!;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => const ExitConfirmationDialog(),
          );
          if (shouldPop ?? false) {
            SystemNavigator.pop();
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                isDarkMode ? Brightness.dark : Brightness.light,
            systemNavigationBarIconBrightness:
                isDarkMode ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
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
                color: isDarkMode
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withValues(alpha: 0.4)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onTabTapped,
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor:
                    isDarkMode ? const Color(0xFFD4AF37) : const Color(0xFF2C3E50),
                unselectedItemColor:
                    isDarkMode ? const Color(0xFFB8B5AD) : const Color(0xFF6B7280),
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: AppLocalizations.of(context)!.home,
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_month),
                    label: AppLocalizations.of(context)!.calendar,
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
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      const CalendarScreen(),
      const SettingScreen(),
      const InfoScreen()
    ];
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
  final String _adUnitId = AdIds.banner;

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
          if (kDebugMode) {
            developer.log('BannerAd failed to load: $err', name: 'Main');
          }
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
