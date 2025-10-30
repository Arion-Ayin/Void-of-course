import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// 앱의 상태(데이터)를 쉽게 관리하게 도와주는 라이브러리를 가져와요. (provider)
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'screens/home_screen.dart';
import 'screens/info_screen.dart';
import 'screens/setting_screen.dart';
import 'services/astro_state.dart';
import 'themes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lioluna/services/locale_provider.dart';
import 'package:lioluna/l10n/app_localizations.dart';
import 'package:upgrader/upgrader.dart';

void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요. (앱이 시작하기 전에 필요한 준비를 해요)
  WidgetsFlutterBinding.ensureInitialized();
  // Google Mobile Ads SDK를 초기화해요.
  MobileAds.instance.initialize();
  // 우리 앱을 실행해요. runApp은 화면에 위젯을 보여주는 함수예요.
  runApp(
    MultiProvider(
      providers: [
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

  @override
  Widget build(BuildContext context) {
    // 테마를 관리하고 앱의 기본 설정을 하는 위젯이에요.
    return ThemeProvider(
      initTheme: Theme.of(context).brightness == Brightness.dark
          ? Themes.darkTheme
          : Themes.lightTheme,
      builder: (context, myTheme) {
        final localeProvider = Provider.of<LocaleProvider>(context);
        return MaterialApp(
          title: 'Void of Course',
          debugShowCheckedModeBanner: false,
          theme: myTheme,
          home: MainAppScreen(),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}

// 앱의 메인 화면 (하단 내비게이션 바가 있는 화면)을 만드는 위젯이에요. StatefulWidget은 상태가 변할 수 있는 위젯이라는 뜻이에요.
class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

// MainAppScreen의 상태를 관리하는 클래스예요. State는 위젯의 변하는 정보를 가지고 있어요.
class _MainAppScreenState extends State<MainAppScreen> {
  // 현재 선택된 하단 내비게이션 바의 인덱스를 저장하는 변수예요. (0: 홈, 1: 설정, 2: 정보)
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 위젯이 완전히 빌드된 후에 딱 한 번 실행돼요.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 현재 설정된 앱의 언어 정보를 가져와요.
      final initialLocale =
          Provider.of<LocaleProvider>(context, listen: false).locale;
      // 만약 언어 정보가 있다면 (null이 아니라면)
      if (initialLocale != null) {
        // AstroState에 현재 언어 정보를 알려줘서 알람 언어를 동기화해요.
        Provider.of<AstroState>(context, listen: false)
            .updateLocale(initialLocale.languageCode);
      }
    });
  }

  // ▼▼▼ 여기가 Provider 문제를 해결하기 위해 Consumer로 수정한 build 메서드입니다 ▼▼▼
  @override
  Widget build(BuildContext context) {
    // AstroState의 변화를 감지하는 Consumer 위젯을 사용합니다.
    return Consumer<AstroState>(
      builder: (context, astroState, child) {
        
        // 1. AstroState가 아직 준비되지 않았다면 로딩 화면을 보여줍니다.
        if (!astroState.isInitialized) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. AstroState에 에러가 있다면 에러 화면을 보여줍니다.
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

        // 3. AstroState가 준비되었다면, LocaleProvider의 변화를 감지합니다.
        //    (Consumer를 중첩하여 사용합니다)
        return Consumer<LocaleProvider>(
          builder: (context, localeProvider, child) {
            
            // 3-1. LocaleProvider에서 현재 언어 코드를 가져옵니다.
            final languageCode = localeProvider.locale?.languageCode ?? 'en';

            // 3-2. Upgrader 인스턴스를 만듭니다.
            final upgrader = Upgrader(
              messages: AppUpgraderMessages(languageCode),
              debugDisplayAlways: true, //ㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡㅡ업데이트 하시겠습니까? 테스트용 
            );

            // 3-3. UpgradeAlert가 포함된 실제 앱 화면을 반환합니다.
            return UpgradeAlert(
              upgrader: upgrader, // <-- 미리 만든 변수 전달.
              showLater: false,
              child: Scaffold(
                // 화면의 뼈대를 만들어요. Scaffold는 기본적인 앱 디자인을 제공하는 위젯이에요.
                // (기존 Scaffold 코드는 여기부터 동일합니다)
                body: Column(
                  children: [
                    // 기존 화면 내용이 광고에 가려지지 않도록 Expanded로 감싸요.
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex, // 현재 선택된 인덱스에 해당하는 화면을 보여줘요.
                        children: _buildScreens(), // 보여줄 화면들의 목록이에요.
                      ),
                    ),
                    // 배너 광고를 보여주는 위젯이에요.
                    const BannerAdWidget(),
                  ],
                ),
                // 화면 하단에 내비게이션 바를 만들어요. bottomNavigationBar는 화면 아래에 있는 메뉴 바예요.
                bottomNavigationBar: Container(
                  // 내비게이션 바의 배경을 꾸며줘요. decoration은 꾸미는 도구예요.
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // 앱의 카드 색상을 배경으로 사용해요.
                    boxShadow: [
                      // 그림자를 만들어서 입체적으로 보이게 해요.
                      // 다크 모드일 때는 검은색, 아닐 때는 회색 그림자를 사용해요.
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3) // 다크 모드면 검은색 (30% 투명도)
                            : Colors.grey.withOpacity(0.2), // 아니면 회색 (20% 투명도)
                        blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요.
                        offset: const Offset(0, -2), // 그림자를 위쪽으로 2만큼 이동시켜요. (x축으로 0, y축으로 -2)
                      ),
                    ],
                  ),
                  // 하단 내비게이션 바 위젯이에요. BottomNavigationBar는 아래쪽에 메뉴 버튼들을 모아둔 거예요.
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex, // 현재 선택된 항목을 표시해요. (어떤 버튼이 눌려있는지)
                    onTap: (index) => setState(() =>
                        _selectedIndex = index), // 항목을 누르면 선택된 인덱스를 바꾸고 화면을 다시 그려요. setState는 화면을 다시 그리라고 알려주는 거예요.
                    backgroundColor: Colors.transparent, // 배경색을 투명하게 해요.
                    elevation: 0, // 그림자를 없애요.
                    // 선택된 항목의 아이콘/글자 색깔을 정해요.
                    selectedItemColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300] // 다크 모드일 때는 밝은 파란색
                            : Colors.blue[600], // 아닐 때는 진한 파란색
                    // 선택되지 않은 항목의 아이콘/글자 색깔을 정해요.
                    unselectedItemColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400] // 다크 모드일 때는 밝은 회색
                            : Colors.grey[600], // 아닐 때는 진한 회색
                    type: BottomNavigationBarType.fixed, // 항목들의 크기를 고정해요. (버튼들이 움직이지 않아요)
                    // 내비게이션 바에 들어갈 항목들이에요. BottomNavigationBarItem은 메뉴 버튼 하나하나를 뜻해요.
                    items: const [
                      BottomNavigationBarItem(
                          icon: Icon(Icons.home), label: '홈'), // 홈 아이콘과 '홈' 글자
                      BottomNavigationBarItem(
                          icon: Icon(Icons.settings), label: '설정'), // 설정 아이콘과 '설정' 글자
                      BottomNavigationBarItem(
                          icon: Icon(Icons.info), label: '정보'), // 정보 아이콘과 '정보' 글자
                    ],
                  ),
                ),
              ), // ▲▲▲ UpgradeAlert가 여기서 닫힙니다. ▲▲▲
            );
          }, // <-- LocaleProvider Consumer 닫기
        );
      }, // <-- AstroState Consumer 닫기
    );
  }

  // 하단 내비게이션 바에 따라 보여줄 화면들의 목록을 만드는 함수예요.
  List<Widget> _buildScreens() {
    return [
      HomeScreen(), // 홈 화면
      const SettingScreen(), // 설정 화면
      const InfoScreen(), // 정보 화면
    ];
  }
}

// 배너 광고를 표시하는 위젯이에요.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  // 실제 광고 단위 ID

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
      // 광고가 로드되지 않았을 때는 아무것도 표시하지 않아요.
      return const SizedBox.shrink();
    }
  }
}

/// 언어 설정에 따라 다른 업그레이드 팝업 메시지를 보여주는 클래스
class AppUpgraderMessages extends UpgraderMessages {
  /// 현재 앱의 언어 코드 (예: 'ko', 'en')
  final String languageCode;
  AppUpgraderMessages(this.languageCode);

  @override
  String get title {
    if (languageCode == 'ko') {
      return '앱 업데이트';
    }
    // 기본값 (영어)
    return 'New Version Available';
  }

  @override
  String get body {
    if (languageCode == 'ko') {
      return '더욱 안정적이고,\n정확한 보이드를 체크해보세요.';
    }
    // 기본값 (영어)
    return 'Experience a more stable and new app.';
  }

  @override
  String get prompt {
    if (languageCode == 'ko') {
      return '지금 업데이트하시겠습니까?';
    }
    // 기본값 (영어)
    return 'Would you like to update now?';
  }

  @override
  String get buttonTitleUpdate {
    if (languageCode == 'ko') {
      return '지금 업데이트';
    }
    // 기본값 (영어)
    return 'Update Now';
  }

  String get buttonTitleLater {
    if (languageCode == 'ko') {
      return '나중에 할래요';
    }
    // 기본값 (영어)
    return 'Later';
  }

  @override
  String get buttonTitleIgnore {
    if (languageCode == 'ko') {
      return '나중에 할래요'; // 다음버전 나오면 될것 2단계 건너뛰기
    }
    // 기본값 (영어)
    return 'Ignore';
  }
}