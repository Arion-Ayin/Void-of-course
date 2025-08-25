import 'package:flutter/material.dart';
// 앱의 상태(데이터)를 쉽게 관리하게 도와주는 라이브러리를 가져와요. (provider)
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'screens/home_screen.dart';
import 'screens/info_screen.dart';
import 'screens/setting_screen.dart';
import 'services/astro_state.dart';
import 'themes.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lioluna/services/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요. (앱이 시작하기 전에 필요한 준비를 해요)
  WidgetsFlutterBinding.ensureInitialized();
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
  
  _MainAppScreenState createState() => _MainAppScreenState();
}

// MainAppScreen의 상태를 관리하는 클래스예요. State는 위젯의 변하는 정보를 가지고 있어요.
class _MainAppScreenState extends State<MainAppScreen> {
  // 현재 선택된 하단 내비게이션 바의 인덱스를 저장하는 변수예요. (0: 홈, 1: 설정, 2: 정보)
  int _selectedIndex = 0;

  
  Widget build(BuildContext context) {
    // AstroState의 변화를 감지해요. Provider.of는 Provider에서 AstroState 정보를 가져와요.
    final astroState = Provider.of<AstroState>(context);

    // 만약 별자리 정보가 아직 준비되지 않았다면,
    if (!astroState.isInitialized) {
      // 로딩 중 화면을 보여줘요.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // 만약 에러가 발생했다면,
    if (astroState.lastError != null) {
      // 에러 메시지를 보여줘요.
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

    // 화면의 뼈대를 만들어요. Scaffold는 기본적인 앱 디자인을 제공하는 위젯이에요.
    return Scaffold(
      // 여러 화면을 겹쳐 놓고, _selectedIndex에 따라 보여줄 화면을 바꿔요. IndexedStack은 여러 위젯을 겹쳐 놓고 하나만 보여줄 때 사용해요.
      body: IndexedStack(
        index: _selectedIndex, // 현재 선택된 인덱스에 해당하는 화면을 보여줘요.
        children: _buildScreens(), // 보여줄 화면들의 목록이에요.
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
          onTap: (index) => setState(() => _selectedIndex = index), // 항목을 누르면 선택된 인덱스를 바꾸고 화면을 다시 그려요. setState는 화면을 다시 그리라고 알려주는 거예요.
          backgroundColor: Colors.transparent, // 배경색을 투명하게 해요.
          elevation: 0, // 그림자를 없애요.
          // 선택된 항목의 아이콘/글자 색깔을 정해요.
          selectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.blue[300] // 다크 모드일 때는 밝은 파란색
              : Colors.blue[600], // 아닐 때는 진한 파란색
          // 선택되지 않은 항목의 아이콘/글자 색깔을 정해요.
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400] // 다크 모드일 때는 밝은 회색
              : Colors.grey[600], // 아닐 때는 진한 회색
          type: BottomNavigationBarType.fixed, // 항목들의 크기를 고정해요. (버튼들이 움직이지 않아요)
          // 내비게이션 바에 들어갈 항목들이에요. BottomNavigationBarItem은 메뉴 버튼 하나하나를 뜻해요.
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'), // 홈 아이콘과 '홈' 글자
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'), // 설정 아이콘과 '설정' 글자
            BottomNavigationBarItem(icon: Icon(Icons.info), label: '정보'), // 정보 아이콘과 '정보' 글자
          ],
        ),
      ),
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