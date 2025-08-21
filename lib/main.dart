// 플러터의 기본 디자인 라이브러리를 가져와요. 화면에 보이는 것들을 만들 때 필요해요.
import 'package:flutter/material.dart';
// 앱의 상태(데이터)를 쉽게 관리하게 도와주는 라이브러리를 가져와요. (provider)
import 'package:provider/provider.dart';
// 천문 계산을 위한 라이브러리를 가져와요. (sweph)
import 'package:sweph/sweph.dart';
// 테마를 부드럽게 바꿔주는 라이브러리를 가져와요. (animated_theme_switcher)
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
// 홈 화면 위젯을 가져와요.
import 'screens/home_screen.dart';
// 정보 화면 위젯을 가져와요.
import 'screens/info_screen.dart';
// 설정 화면 위젯을 가져와요.
import 'screens/setting_screen.dart';
// 별자리 계산과 관련된 우리 앱의 기능을 가져와요. (AstroState)
import 'services/astro_state.dart';
// 우리가 만든 테마 파일(밝은 모드, 어두운 모드)을 가져와요.
import 'themes.dart';

// 앱이 시작될 때 가장 먼저 실행되는 함수예요. 모든 플러터 앱은 main 함수에서 시작해요.
void main() async {
  // 플러터 위젯들이 준비될 때까지 기다려요. (앱이 시작하기 전에 필요한 준비를 해요)
  WidgetsFlutterBinding.ensureInitialized();
  // 우리 앱을 실행해요. runApp은 화면에 위젯을 보여주는 함수예요.
  runApp(const MyApp());
}

// 오류가 발생했을 때 보여줄 화면을 만드는 위젯이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class ErrorScreen extends StatelessWidget {
  final String error; // 보여줄 오류 메시지예요. error라는 이름의 상자에 넣어둘 거예요.
  // 오류 메시지를 꼭 받아야 해요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const ErrorScreen({super.key, required this.error});
  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 기본적인 앱 디자인을 제공하는 위젯이에요. MaterialApp은 앱의 가장 기본적인 틀을 만들어요.
    return MaterialApp(
      // 화면의 뼈대를 만들어요. Scaffold는 기본적인 앱 디자인을 제공하는 위젯이에요.
      home: Scaffold(
        // 화면의 가운데에 내용을 놓아요. Center는 위젯을 가운데로 정렬해요.
        body: Center(
          // 내용 주변에 여백을 줘요. Padding은 위젯 주변에 여백을 줘요.
          child: Padding(
            padding: const EdgeInsets.all(16.0), // 모든 방향으로 16만큼 여백을 줘요.
            // 오류 메시지를 보여주는 글자예요. Text는 글자를 보여줘요.
            child: Text(
              '오류가 발생하여 앱을 실행할 수 없습니다.\n\n$error', // 오류 메시지를 포함한 안내 문구예요. \n은 줄 바꿈을 뜻해요.
              textAlign: TextAlign.center, // 글자를 가운데 정렬해요.
              style: const TextStyle(color: Colors.red, fontSize: 16), // 글자색은 빨간색, 크기는 16
            ),
          ),
        ),
      ),
    );
  }
}

// 우리 앱의 가장 기본적인 위젯이에요. StatefulWidget은 상태가 변할 수 있는 위젯이라는 뜻이에요.
class MyApp extends StatefulWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const MyApp({super.key});
  @override
  // MyApp의 상태를 관리하는 클래스를 만들어요. createState는 위젯의 상태를 만드는 함수예요.
  State<MyApp> createState() => _MyAppState();
}

// MyApp의 상태를 관리하는 클래스예요. State는 위젯의 변하는 정보를 가지고 있어요.
class _MyAppState extends State<MyApp> {
  // 앱이 시작될 때 필요한 초기화 작업을 저장할 변수예요. Future는 시간이 좀 걸리는 작업이라는 뜻이에요.
  late Future<void> _initialization; // late는 나중에 값을 넣어줄 거라는 뜻이에요.

  @override
  // 이 위젯이 처음 만들어질 때 한 번만 실행되는 함수예요. initState는 위젯이 화면에 나타나기 전에 준비하는 곳이에요.
  void initState() {
    super.initState(); // 부모 클래스의 initState 함수를 먼저 실행해요. (필수)
    // Sweph 라이브러리를 초기화하는 함수를 호출하고 결과를 _initialization에 저장해요.
    _initialization = _initSweph();
  }

  // Sweph 라이브러리를 초기화하는 비동기 함수예요. async는 이 함수 안에 시간이 걸리는 작업이 있다는 뜻이에요.
  Future<void> _initSweph() async {
    // try는 "일단 시도해봐"라는 뜻이에요. 혹시 문제가 생길 수도 있는 코드를 여기에 넣어요.
    try {
      // Sweph 라이브러리를 초기화하고, 필요한 데이터 파일들을 불러와요. await는 이 작업이 끝날 때까지 기다리라는 뜻이에요.
      await Sweph.init(epheAssets: [
        'assets/sweph/semo_18.se1', // 첫 번째 데이터 파일 경로
        'assets/sweph/sepl_18.se1', // 두 번째 데이터 파일 경로
      ]);
    // catch는 "만약에 문제가 생기면 이렇게 해"라는 뜻이에요. e는 어떤 문제가 생겼는지 알려주는 정보예요.
    } catch (e) {
      // 초기화 중에 오류가 발생하면, 오류 메시지를 포함한 예외를 발생시켜요. throw Exception은 오류를 밖으로 던지는 거예요.
      throw Exception('Sweph 초기화 중 오류가 발생했습니다: $e');
    }
  }

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // _initialization 작업의 상태에 따라 다른 화면을 보여줘요. FutureBuilder는 Future의 상태에 따라 다른 위젯을 보여줘요.
    return FutureBuilder(
      future: _initialization, // _initialization 작업이 끝날 때까지 기다려요.
      builder: (context, snapshot) {
        // 만약 초기화 작업이 아직 끝나지 않았다면 (로딩 중이라면),
        if (snapshot.connectionState != ConnectionState.done) {
          // 로딩 중 화면을 보여줘요.
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())), // 가운데에 동그란 로딩 아이콘을 보여줘요.
          );
        } else if (snapshot.hasError) {
          // 만약 초기화 작업 중에 오류가 발생했다면,
          return ErrorScreen(error: snapshot.error.toString()); // 오류 화면을 보여줘요. snapshot.error는 발생한 오류 정보예요.
        }

        // 초기화 작업이 성공적으로 끝나면, 앱의 주요 내용을 보여줘요.
        return ChangeNotifierProvider(
          create: (context) {
            // AstroState 객체를 만들고 초기화해요. AstroState는 앱의 중요한 정보들을 가지고 있어요.
            final astroState = AstroState();
            astroState.initialize();
            return astroState; // AstroState를 앱 전체에서 사용할 수 있게 제공해요. (Provider를 통해)
          },
          // AstroState의 변화를 감지하고 화면을 다시 그리는 위젯이에요. Consumer는 Provider의 변화를 감지해요.
          child: Consumer<AstroState>(
            builder: (context, astroState, child) {
              // 테마를 관리하는 위젯이에요. ThemeProvider는 앱의 테마를 쉽게 바꿀 수 있게 해줘요.
              return ThemeProvider(
                // 초기 테마를 설정해요. 현재 시스템 테마가 다크 모드인지에 따라 결정해요.
                initTheme: Theme.of(context).brightness == Brightness.dark
                    ? Themes.darkTheme // 다크 모드면 어두운 테마
                    : Themes.lightTheme, // 아니면 밝은 테마
                builder: (context, myTheme) {
                  // 앱의 기본적인 설정을 하는 위젯이에요. MaterialApp은 앱의 가장 기본적인 틀을 만들어요.
                  return MaterialApp(
                    title: 'Void of Course', // 앱의 제목이에요.
                    debugShowCheckedModeBanner: false, // 디버그 배너를 숨겨요. (오른쪽 위에 DEBUG라고 뜨는 글자)
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

// 앱의 메인 화면 (하단 내비게이션 바가 있는 화면)을 만드는 위젯이에요. StatefulWidget은 상태가 변할 수 있는 위젯이라는 뜻이에요.
class MainAppScreen extends StatefulWidget {
  @override
  // MainAppScreen의 상태를 관리하는 클래스를 만들어요. createState는 위젯의 상태를 만드는 함수예요.
  _MainAppScreenState createState() => _MainAppScreenState();
}

// MainAppScreen의 상태를 관리하는 클래스예요. State는 위젯의 변하는 정보를 가지고 있어요.
class _MainAppScreenState extends State<MainAppScreen> {
  // 현재 선택된 하단 내비게이션 바의 인덱스를 저장하는 변수예요. (0: 홈, 1: 설정, 2: 정보)
  int _selectedIndex = 0;

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // AstroState의 변화를 감지해요. Provider.of는 Provider에서 AstroState 정보를 가져와요.
    final astroState = Provider.of<AstroState>(context);
    
    // 만약 별자리 정보가 아직 준비되지 않았다면,
    if (!astroState.isInitialized) {
      // 로딩 중 화면을 보여줘요.
      return const Scaffold(body: Center(child: CircularProgressIndicator())); // 가운데에 동그란 로딩 아이콘을 보여줘요.
    }
    // 만약 에러가 발생했다면,
    if (astroState.lastError != null) {
      // 에러 메시지를 보여줘요. Text는 글자를 보여줘요.
      return Center(child: Text('Error: ${astroState.lastError}'));
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