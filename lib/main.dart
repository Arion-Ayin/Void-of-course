import 'package:flutter/material.dart'; // 플러터의 기본 디자인 라이브러리를 가져와요.
import 'package:provider/provider.dart'; // 앱의 상태(데이터)를 쉽게 관리하게 도와주는 라이브러리를 가져와요.
import 'package:sweph/sweph.dart'; // 천문 계산을 위한 라이브러리를 가져와요.
import 'package:animated_theme_switcher/animated_theme_switcher.dart'; // 테마를 부드럽게 바꿔주는 라이브러리를 가져와요.
import 'screens/home_screen.dart'; // 홈 화면 위젯을 가져와요.
import 'screens/info_screen.dart'; // 정보 화면 위젯을 가져와요.
import 'screens/setting_screen.dart'; // 설정 화면 위젯을 가져와요.
import 'services/astro_state.dart'; // 별자리 계산과 관련된 우리 앱의 기능을 가져와요.
import 'themes.dart'; // 우리가 만든 테마 파일(밝은 모드, 어두운 모드)을 가져와요.

// 앱이 시작될 때 가장 먼저 실행되는 함수예요.
void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요.
  WidgetsFlutterBinding.ensureInitialized();
  // 우리 앱을 실행해요.
  runApp(const MyApp());
}

// 오류가 발생했을 때 보여줄 화면을 만드는 위젯이에요.
class ErrorScreen extends StatelessWidget {
  final String error; // 보여줄 오류 메시지예요.
  // 오류 메시지를 꼭 받아야 해요.
  const ErrorScreen({super.key, required this.error});
  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 기본적인 앱 디자인을 제공하는 위젯이에요.
    return MaterialApp(
      // 화면의 뼈대를 만들어요.
      home: Scaffold(
        // 화면의 가운데에 내용을 놓아요.
        body: Center(
          // 내용 주변에 여백을 줘요.
          child: Padding(
            padding: const EdgeInsets.all(16.0), // 모든 방향으로 16만큼 여백을 줘요.
            // 오류 메시지를 보여주는 글자예요.
            child: Text(
              '오류가 발생하여 앱을 실행할 수 없습니다.\n\n$error', // 오류 메시지를 포함한 안내 문구예요.
              textAlign: TextAlign.center, // 글자를 가운데 정렬해요.
              style: const TextStyle(color: Colors.red, fontSize: 16), // 글자색은 빨간색, 크기는 16
            ),
          ),
        ),
      ),
    );
  }
}

// 우리 앱의 가장 기본적인 위젯이에요.
class MyApp extends StatefulWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요.
  const MyApp({super.key});
  @override
  // MyApp의 상태를 관리하는 클래스를 만들어요.
  State<MyApp> createState() => _MyAppState();
}

// MyApp의 상태를 관리하는 클래스예요.
class _MyAppState extends State<MyApp> {
  // 앱이 시작될 때 필요한 초기화 작업을 저장할 변수예요.
  late Future<void> _initialization;

  @override
  // 이 위젯이 처음 만들어질 때 한 번만 실행되는 함수예요.
  void initState() {
    super.initState(); // 부모 클래스의 initState 함수를 먼저 실행해요.
    // Sweph 라이브러리를 초기화하는 함수를 호출하고 결과를 저장해요.
    _initialization = _initSweph();
  }

  // Sweph 라이브러리를 초기화하는 비동기 함수예요.
  Future<void> _initSweph() async {
    try {
      // Sweph 라이브러리를 초기화하고, 필요한 데이터 파일들을 불러와요.
      await Sweph.init(epheAssets: [
        'assets/sweph/semo_18.se1', // 첫 번째 데이터 파일 경로
        'assets/sweph/sepl_18.se1', // 두 번째 데이터 파일 경로
      ]);
    } catch (e) {
      // 초기화 중에 오류가 발생하면, 오류 메시지를 포함한 예외를 발생시켜요.
      throw Exception('Sweph 초기화 중 오류가 발생했습니다: $e');
    }
  }

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // _initialization 작업의 상태에 따라 다른 화면을 보여줘요.
    return FutureBuilder(
      future: _initialization, // _initialization 작업이 끝날 때까지 기다려요.
      builder: (context, snapshot) {
        // 만약 초기화 작업이 아직 끝나지 않았다면,
        if (snapshot.connectionState != ConnectionState.done) {
          // 로딩 중 화면을 보여줘요.
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())), // 가운데에 동그란 로딩 아이콘을 보여줘요.
          );
        } else if (snapshot.hasError) {
          // 만약 초기화 작업 중에 오류가 발생했다면,
          return ErrorScreen(error: snapshot.error.toString()); // 오류 화면을 보여줘요.
        }

        // 초기화 작업이 성공적으로 끝나면, 앱의 주요 내용을 보여줘요.
        return ChangeNotifierProvider(
          create: (context) {
            // AstroState 객체를 만들고 초기화해요.
            final astroState = AstroState();
            astroState.initialize();
            return astroState; // AstroState를 앱 전체에서 사용할 수 있게 제공해요.
          },
          // AstroState의 변화를 감지하고 화면을 다시 그리는 위젯이에요.
          child: Consumer<AstroState>(
            builder: (context, astroState, child) {
              // 테마를 관리하는 위젯이에요.
              return ThemeProvider(
                // 초기 테마를 설정해요. 현재 시스템 테마가 다크 모드인지에 따라 결정해요.
                initTheme: Theme.of(context).brightness == Brightness.dark
                    ? Themes.darkTheme // 다크 모드면 어두운 테마
                    : Themes.lightTheme, // 아니면 밝은 테마
                builder: (context, myTheme) {
                  // 앱의 기본적인 설정을 하는 위젯이에요.
                  return MaterialApp(
                    title: 'Void of Course', // 앱의 제목이에요.
                    debugShowCheckedModeBanner: false, // 디버그 배너를 숨겨요.
                    theme: myTheme, // 현재 설정된 테마를 적용해요.
                    home: MainAppScreen(), // 앱의 메인 화면을 보여줘요.
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// 앱의 메인 화면 (하단 내비게이션 바가 있는 화면)을 만드는 위젯이에요.
class MainAppScreen extends StatefulWidget {
  @override
  // MainAppScreen의 상태를 관리하는 클래스를 만들어요.
  _MainAppScreenState createState() => _MainAppScreenState();
}

// MainAppScreen의 상태를 관리하는 클래스예요.
class _MainAppScreenState extends State<MainAppScreen> {
  // 현재 선택된 하단 내비게이션 바의 인덱스를 저장하는 변수예요. (0: 홈, 1: 설정, 2: 정보)
  int _selectedIndex = 0;

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // AstroState의 변화를 감지해요.
    final astroState = Provider.of<AstroState>(context);
    
    // 만약 별자리 정보가 아직 준비되지 않았다면,
    if (!astroState.isInitialized) {
      // 로딩 중 화면을 보여줘요.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // 만약 에러가 발생했다면,
    if (astroState.lastError != null) {
      // 에러 메시지를 보여줘요.
      return Center(child: Text('Error: ${astroState.lastError}'));
    }

    // 화면의 뼈대를 만들어요.
    return Scaffold(
      // 여러 화면을 겹쳐 놓고, _selectedIndex에 따라 보여줄 화면을 바꿔요.
      body: IndexedStack(
        index: _selectedIndex, // 현재 선택된 인덱스에 해당하는 화면을 보여줘요.
        children: _buildScreens(), // 보여줄 화면들의 목록이에요.
      ),
      // 화면 하단에 내비게이션 바를 만들어요.
      bottomNavigationBar: Container(
        // 내비게이션 바의 배경을 꾸며줘요.
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, // 앱의 카드 색상을 배경으로 사용해요.
          boxShadow: [
            // 그림자를 만들어서 입체적으로 보이게 해요.
            BoxShadow(
              // 다크 모드일 때는 검은색, 아닐 때는 회색 그림자를 사용해요.
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요.
              offset: const Offset(0, -2), // 그림자를 위쪽으로 2만큼 이동시켜요.
            ),
          ],
        ),
        // 하단 내비게이션 바 위젯이에요.
        child: BottomNavigationBar(
          currentIndex: _selectedIndex, // 현재 선택된 항목을 표시해요.
          onTap: (index) => setState(() => _selectedIndex = index), // 항목을 누르면 선택된 인덱스를 바꾸고 화면을 다시 그려요.
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
          type: BottomNavigationBarType.fixed, // 항목들의 크기를 고정해요.
          // 내비게이션 바에 들어갈 항목들이에요.
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
