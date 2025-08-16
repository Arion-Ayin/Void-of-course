// main.dart

// Flutter의 기본 재료들을 가져옵니다. 화면을 만드는 데 꼭 필요해요.
import 'package:flutter/material.dart';
// 앱의 중요한 데이터(상태)를 여러 곳에서 같이 쓰게 해주는 도구(프로바이더)를 가져옵니다.
import 'package:provider/provider.dart';
// 별자리 계산을 위한 특별한 도구(Sweph)를 가져옵니다.
import 'package:sweph/sweph.dart';
// 화면의 색깔이 부드럽게 바뀌는 애니메이션을 도와주는 도구(테마 스위처)를 가져옵니다.
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
// 우리가 만든 '홈' 화면 파일을 가져옵니다.
import 'screens/home_screen.dart';
// 우리가 만든 '정보' 화면 파일을 가져옵니다.
import 'screens/info_screen.dart';
// 우리가 만든 '별자리 정보' 데이터 관리 파일을 가져옵니다.
import 'services/astro_state.dart';
// 시간대(타임존)를 다루는 도구를 가져옵니다.
import 'services/timezone_helper.dart';
// 앱의 전체적인 색깔과 디자인을 정해둔 파일을 가져옵니다.
import 'themes.dart';

// main 함수는 앱이 가장 먼저 시작되는 곳입니다.
void main() async {
  // Flutter 앱이 시작될 준비를 하도록 명령합니다.
  WidgetsFlutterBinding.ensureInitialized();
  // 혹시 오류가 생길 수도 있으니, 일단 시도해봅니다.
  try {
    // 별자리 계산 도구(Sweph)를 준비시킵니다.
    await Sweph.init(epheAssets: [
      // Sweph가 계산에 필요한 파일들을 앱의 'assets' 폴더에서 가져옵니다.
      'assets/sweph/semo_18.se1',
      'assets/sweph/sepl_18.se1',
    ]);
    // 준비가 다 끝나면, 우리 앱을 시작합니다.
    runApp(const MyApp());
  } catch (e) {
    // 만약 문제가 생기면, '오류가 발생했다'라는 메시지를 보여줍니다.
    print('Sweph 초기화 중 오류가 발생했습니다: $e');
    // 오류가 발생했음을 알려주는 화면을 보여줍니다.
    runApp(ErrorScreen(error: '앱 초기화 오류: $e'));
  }
}

// ErrorScreen은 앱이 제대로 시작되지 않았을 때 보여주는 화면입니다.
class ErrorScreen extends StatelessWidget {
  // 오류 내용을 담는 변수입니다.
  final String error;
  // ErrorScreen 위젯을 만듭니다. 오류 내용을 꼭 받아야 합니다.
  const ErrorScreen({super.key, required this.error});
  // 화면에 무엇을 보여줄지 결정하는 함수입니다.
  @override
  Widget build(BuildContext context) {
    // MaterialApp은 앱의 가장 기본적인 틀을 제공합니다.
    return MaterialApp(
      // Scaffold는 앱 화면의 기본 틀(바탕)입니다.
      home: Scaffold(
        // body는 화면의 주요 내용을 담는 부분입니다.
        body: Center(
          // 중앙에 여백을 줍니다.
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // 오류 메시지를 보여주는 텍스트입니다.
            child: Text(
              '오류가 발생하여 앱을 실행할 수 없습니다.\n\n$error',
              // 글자를 가운데에 정렬합니다.
              textAlign: TextAlign.center,
              // 글자의 디자인을 정합니다. 빨간색 글씨로 보여줍니다.
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// MyApp은 우리 앱의 가장 기본적인 틀을 만드는 부분입니다.
// 앱의 화면이 바뀌어야 하므로 'StatefulWidget'을 사용합니다.
class MyApp extends StatefulWidget {
  // MyApp 위젯을 만듭니다.
  const MyApp({super.key});
  // 이 화면의 상태(데이터)를 관리하는 곳을 만듭니다.
  @override
  State<MyApp> createState() => _MyAppState();
}

// _MyAppState는 MyApp의 상태를 실제로 관리하는 곳입니다.
class _MyAppState extends State<MyApp> {
  // 현재 선택된 화면이 몇 번째인지 기억하는 변수입니다.
  int _selectedIndex = 0;

  // 화면에 무엇을 보여줄지 결정하는 중요한 함수입니다.
  @override
  Widget build(BuildContext context) {
    // ChangeNotifierProvider는 'AstroState'라는 데이터를 모든 위젯이 같이 쓰게 해주는 도구입니다.
    return ChangeNotifierProvider(
      // AstroState의 새 데이터를 만듭니다.
      create: (context) {
        final astroState = AstroState();
        // AstroState 초기화 함수를 호출합니다.
        astroState.initialize();
        return astroState;
      },
      // Consumer는 AstroState의 데이터가 바뀔 때마다 화면을 새로고침해줍니다.
      child: Consumer<AstroState>(
        // AstroState의 데이터를 받아서 화면을 만드는 함수입니다.
        builder: (context, astroState, child) {
          // ThemeProvider는 앱의 테마(색깔)를 관리하고 바꿔주는 도구입니다.
          return ThemeProvider(
            // 앱이 시작될 때 어떤 테마로 시작할지 정합니다.
            initTheme: astroState.isDarkMode ? Themes.darkTheme : Themes.lightTheme,
            // 테마 정보를 받아서 화면을 만드는 함수입니다.
            builder: (context, myTheme) {
              // MaterialApp은 앱의 가장 기본적인 틀을 제공합니다.
              return MaterialApp(
                // 앱의 제목을 정합니다.
                title: 'Void of Course',
                // 디버그 배너(오른쪽 위 빨간 띠)를 없앱니다.
                debugShowCheckedModeBanner: false,
                // 이 앱에서 사용할 테마(색깔)를 정해줍니다.
                theme: myTheme,
                // Scaffold는 앱 화면의 기본 틀(바탕)입니다.
                home: Scaffold(
                  // body는 화면의 주요 내용을 담는 부분입니다.
                  // IndexedStack은 여러 화면을 겹쳐 놓고, 인덱스에 따라 하나만 보여주는 위젯입니다.
                  body: IndexedStack(
                    // 현재 보여줄 화면의 번호(인덱스)입니다.
                    index: _selectedIndex,
                    // 보여줄 화면들의 목록입니다.
                    children: _buildScreens(),
                  ),
                  // bottomNavigationBar는 화면의 맨 아래에 있는 메뉴바입니다.
                  bottomNavigationBar: Container(
                    // 메뉴바의 디자인을 정합니다.
                    decoration: BoxDecoration(
                      // 배경색을 테마에 맞춰 정합니다.
                      color: myTheme.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
                      // 그림자 효과를 줍니다.
                      boxShadow: [
                        BoxShadow(
                          color: myTheme.brightness == Brightness.dark
                              ? Colors.black.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    // 실제 메뉴바 위젯입니다.
                    child: BottomNavigationBar(
                      // 현재 선택된 메뉴의 번호입니다.
                      currentIndex: _selectedIndex,
                      // 메뉴를 눌렀을 때 실행되는 함수입니다.
                      onTap: (index) => setState(() => _selectedIndex = index),
                      // 배경색을 투명하게 만듭니다. (위의 Container 색상을 사용)
                      backgroundColor: Colors.transparent,
                      // 메뉴바의 그림자를 없앱니다.
                      elevation: 0,
                      // 선택된 메뉴 아이콘의 색깔을 테마에 맞춰 정합니다.
                      selectedItemColor: myTheme.brightness == Brightness.dark ? Colors.blue[300] : Colors.blue[600],
                      // 선택되지 않은 메뉴 아이콘의 색깔을 테마에 맞춰 정합니다.
                      unselectedItemColor: myTheme.brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[600],
                      // 메뉴 아이템의 디자인이 고정되도록 합니다.
                      type: BottomNavigationBarType.fixed,
                      // 메뉴에 들어갈 아이템들을 만듭니다.
                      items: const [
                        // 첫 번째 아이템: 홈 버튼
                        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                        // 두 번째 아이템: 정보 버튼
                        BottomNavigationBarItem(icon: Icon(Icons.info), label: 'in'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 앱의 화면들을 목록으로 만들어주는 함수입니다.
  List<Widget> _buildScreens() {
    return [
      HomeScreen(), // HomeScreen 위젯을 만듭니다.
      InfoScreen(), // InfoScreen 위젯을 만듭니다.
    ];
  }
}