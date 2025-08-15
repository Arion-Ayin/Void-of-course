// InfoScreen.dart

// Flutter의 기본적인 재료들을 가져옵니다. 화면을 만드는 데 꼭 필요해요.
import 'package:flutter/material.dart';
// 앱의 데이터(상태)를 여러 곳에서 같이 쓰게 해주는 도구(프로바이더)를 가져옵니다.
import 'package:provider/provider.dart';
// 우리가 만든 '별자리 정보' 데이터 관리 파일을 가져옵니다.
import '../services/astro_state.dart';
// 앱의 전체적인 색깔과 디자인을 정해둔 파일을 가져옵니다.
import '../themes.dart';
// 화면의 색깔이 부드럽게 바뀌는 애니메이션을 도와주는 도구(테마 스위처)를 가져옵니다.
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

// InfoScreen은 우리 앱의 '정보' 화면(위젯)입니다.
class InfoScreen extends StatefulWidget {
  // InfoScreen 위젯을 만듭니다.
  const InfoScreen({super.key});

  // 이 화면의 상태(데이터)를 관리하는 곳을 만듭니다.
  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

// _InfoScreenState는 InfoScreen의 상태를 실제로 관리하는 곳입니다.
// 'with TickerProviderStateMixin'은 애니메이션을 만들 때 필요한 도구입니다.
class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  // 아이콘의 회전 애니메이션을 조절하는 도구입니다.
  late AnimationController _iconRotationController;
  // 아이콘의 회전 각도를 계산하는 도구입니다.
  late Animation<double> _iconRotationAnimation;

  // 화면이 처음 만들어질 때 딱 한 번 실행되는 함수입니다.
  @override
  void initState() {
    // 부모 클래스의 initState 함수를 먼저 불러옵니다.
    super.initState();

    // 아이콘 회전 애니메이션 컨트롤러를 만듭니다.
    _iconRotationController = AnimationController(
      // 애니메이션이 0.8초 동안 진행됩니다.
      duration: const Duration(milliseconds: 800),
      // 애니메이션을 부드럽게 만드는 도구(vsync)를 연결합니다.
      vsync: this,
    );

    // 아이콘 회전 애니메이션의 시작과 끝을 정합니다.
    _iconRotationAnimation = Tween<double>(
      // 시작 각도
      begin: 0.0,
      // 끝 각도
      end: 1.0,
    ).animate(CurvedAnimation(
      // 애니메이션 컨트롤러를 연결합니다.
      parent: _iconRotationController,
      // 애니메이션 속도를 더 부드럽게 만듭니다.
      curve: Curves.easeInOutCubic,
    ));
  }

  // 이 화면이 사라질 때 실행되는 함수입니다.
  @override
  void dispose() {
    // 애니메이션 컨트롤러를 정리하여 메모리 낭비를 막습니다.
    _iconRotationController.dispose();
    // 부모 위젯의 dispose 함수도 꼭 불러줍니다.
    super.dispose();
  }

  // 테마(화면의 색깔)가 바뀔 때 실행되는 함수입니다.
  void _onThemeChanged() {
    // 아이콘 회전 애니메이션을 처음부터 끝까지 실행합니다.
    _iconRotationController.forward().then((_) {
      // 애니메이션이 끝나면 초기 상태로 되돌립니다.
      _iconRotationController.reset();
    });
  }

  // 화면에 무엇을 보여줄지 결정하는 중요한 함수입니다.
  @override
  Widget build(BuildContext context) {
    // Builder는 context를 다시 가져와서 위젯을 만들어주는 위젯입니다.
    return Builder(
      builder: (context) {
        // 'Scaffold'는 앱 화면의 기본 틀(바탕)입니다.
        return Scaffold(
          // AppBar는 화면의 맨 위에 있는 막대입니다.
          appBar: AppBar(
            // title은 AppBar의 제목 부분입니다.
            title: Row(
              // 아이콘과 텍스트를 나란히 놓습니다.
              children: [
                // 정보 아이콘을 보여줍니다.
                Icon(
                    // 정보 아이콘
                    Icons.info_outline,
                    // 어두운 모드일 때 파란색, 밝은 모드일 때 짙은 파란색으로 색을 정합니다.
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : Colors.blue[600],
                    // 아이콘 크기
                    size: 24
                ),
                // 아이콘과 텍스트 사이에 작은 공간을 둡니다.
                const SizedBox(width: 8),
                // '앱 정보'라는 텍스트를 보여줍니다.
                Text(
                  '앱 정보',
                  // 텍스트의 디자인을 정합니다.
                  style: TextStyle(
                    // 어두운 모드일 때 흰색, 밝은 모드일 때 검은색으로 글자 색을 정합니다.
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            // AppBar의 배경색을 테마에 맞춰 정합니다.
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            // AppBar의 글자색을 테마에 맞춰 정합니다.
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            // AppBar 아래에 그림자를 살짝 넣어줍니다.
            elevation: Theme.of(context).appBarTheme.elevation,
            // actions는 AppBar의 오른쪽 부분에 들어가는 위젯들입니다.
            actions: [
              // ThemeSwitcher는 테마를 바꾸는 기능을 제공하는 위젯입니다.
              ThemeSwitcher(
                // 'clipper' 매개변수는 동그란 애니메이션을 만들 때 사용합니다.
                // 이 코드에서는 사용하지 않아도 됩니다. (이전 오류 해결을 위해 제거됨)
                builder: (context) {
                  // 버튼의 크기를 정해주는 컨테이너입니다.
                  return Container(
                    constraints: const BoxConstraints(
                      // 버튼의 최소 가로 크기
                      minWidth: 48,
                      // 버튼의 최소 세로 크기
                      minHeight: 48,
                    ),
                    // 애니메이션을 부드럽게 만들어주는 위젯입니다.
                    child: AnimatedBuilder(
                      // 어떤 애니메이션을 사용할지 정합니다.
                      animation: _iconRotationAnimation,
                      // 애니메이션이 바뀔 때마다 실행되는 함수입니다.
                      builder: (context, child) {
                        // 아이콘을 회전시키는 효과를 줍니다.
                        return Transform.rotate(
                          // 회전하는 각도를 계산합니다.
                          angle: _iconRotationAnimation.value * 2 * 3.14159,
                          // 아이콘 버튼입니다.
                          child: IconButton(
                            // 아이콘 모양을 정합니다.
                            icon: Icon(
                              // 어두운 모드일 때 해 아이콘, 밝은 모드일 때 달 아이콘을 보여줍니다.
                              Theme.of(context).brightness == Brightness.dark ? Icons.wb_sunny : Icons.nightlight_round,
                              // 아이콘의 색깔을 정합니다.
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.orange : Colors.indigo,
                            ),
                            // 버튼을 눌렀을 때 실행되는 함수입니다.
                            onPressed: () {
                              // 테마 변경 애니메이션을 시작합니다.
                              _onThemeChanged();
                              // 테마를 바꾸는 도구를 가져옵니다.
                              final switcher = ThemeSwitcher.of(context);
                              // 현재 테마가 무엇인지 확인합니다.
                              final currentTheme = Theme.of(context);
                              // 현재 테마가 어두운 모드라면,
                              if (currentTheme.brightness == Brightness.dark) {
                                // 밝은 모드로 바꿔줍니다.
                                switcher.changeTheme(theme: Themes.lightTheme);
                              } else {
                                // 밝은 모드라면, 어두운 모드로 바꿔줍니다.
                                switcher.changeTheme(theme: Themes.darkTheme);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          // body는 화면의 주요 내용을 담는 부분입니다.
          body: Container(
            // 컨테이너의 가로 길이를 화면 전체로 설정합니다.
            width: double.infinity,
            // 컨테이너의 세로 길이를 화면 전체로 설정합니다.
            height: double.infinity,
            // 컨테이너가 화면 전체를 채우도록 합니다.
            constraints: const BoxConstraints.expand(),
            // 컨테이너의 배경을 그라데이션으로 만듭니다.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                // 그라데이션이 시작되는 위치
                begin: Alignment.topCenter,
                // 그라데이션이 끝나는 위치
                end: Alignment.bottomCenter,
                // 현재 테마에 따라 그라데이션 색깔을 다르게 정합니다.
                colors: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                  : [Colors.blue[50]!, Colors.white],
              ),
            ),
            // SafeArea는 화면의 상단 노치(notch)나 하단 바를 피해서 내용을 보여주는 위젯입니다.
            child: SafeArea(
              // 화면의 내용이 많아도 스크롤할 수 있게 해주는 위젯입니다.
              child: SingleChildScrollView(
                // 스크롤이 끝에 도달했을 때 튕기는 효과를 없앱니다.
                physics: const ClampingScrollPhysics(),
                // 모든 방향에 20.0만큼의 여백을 줍니다.
                padding: const EdgeInsets.all(20.0),
                // 컨테이너의 크기에 제약을 줍니다.
                child: ConstrainedBox(
                  // 최소 높이를 800으로 설정합니다.
                  constraints: const BoxConstraints(
                    minHeight: 800,
                  ),
                  // 자식 위젯들을 세로로 나열하는 위젯입니다.
                  child: Column(
                    // 세로 길이를 자식 위젯의 크기만큼만 사용합니다.
                    mainAxisSize: MainAxisSize.min,
                    // 자식 위젯들을 여기에 넣어줍니다.
                    children: [
                      // 앱의 헤더(로고, 제목) 부분을 만드는 위젯입니다.
                      _buildAppHeader(context),
                      // 헤더 아래에 30만큼의 공간을 줍니다.
                      const SizedBox(height: 30),
                      // 앱의 기본 정보를 보여주는 카드입니다.
                      _buildInfoCard(
                        icon: Icons.star,
                        title: 'Who we are',
                        subtitle: '사자의 눈으로 세상을 헤아립니다.',
                        iconColor: Colors.amber,
                      ),
                      // 카드 아래에 20만큼의 공간을 줍니다.
                      const SizedBox(height: 20),
                      // 버전 정보를 보여주는 카드입니다.
                      _buildInfoCard(
                        icon: Icons.update,
                        title: '버전 정보',
                        subtitle: '현재 버전: 1.0.0' 
                            '• 달 위상 계산'
                            '• 보이드 오브 코스'
                            '• 다크/라이트 모드'
                            '• 실시간 업데이트',
                        iconColor: Colors.green,
                      ),
                      // 카드 아래에 20만큼의 공간을 줍니다.
                      const SizedBox(height: 20),
                      // 개발자 정보를 보여주는 카드입니다.
                      _buildInfoCard(
                        icon: Icons.person,
                        title: '개발자 Lio',
                        subtitle: '점성학을 좋아하는 개발자.',
                        iconColor: Colors.blue,
                      ),
                      // 카드 아래에 20만큼의 공간을 줍니다.
                      const SizedBox(height: 20),
                      // 기술 스택 정보를 보여주는 카드입니다.
                      _buildInfoCard(
                        icon: Icons.code,
                        title: '기술 스택',
                        subtitle: '• Flutter' 
                            '• Swiss Ephemeris' 
                            '• Provider 패턴'
                            '• Material Design 3',
                        iconColor: Colors.purple,
                      ),
                      // 카드 아래에 20만큼의 공간을 줍니다.
                      const SizedBox(height: 20),
                      // 업데이트 로그 정보를 보여주는 카드입니다.
                      _buildInfoCard(
                        icon: Icons.history,
                        title: '업데이트 로그',
                        subtitle: 'v1.0.0 (2025-08-14)'
                            '• 달 위상 계산 기능'
                            '• 보이드 오브 코스 계산'
                            '• 다크/라이트 모드 지원'
                            '• 한국어 지원',
                        iconColor: Colors.orange,
                      ),
                      // 카드 아래에 30만큼의 공간을 줍니다.
                      const SizedBox(height: 30),
                      // 저작권 정보를 보여주는 컨테이너입니다.
                      Container(
                        // 컨테이너 안쪽에 여백을 줍니다.
                        padding: const EdgeInsets.all(16),
                        // 컨테이너의 디자인을 정합니다.
                        decoration: BoxDecoration(
                          // 배경색은 테마에 맞춥니다.
                          color: Theme.of(context).cardColor,
                          // 모서리를 둥글게 만듭니다.
                          borderRadius: BorderRadius.circular(16),
                          // 그림자 효과를 줍니다.
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).shadowColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        // 저작권 텍스트입니다.
                        child: Text(
                          '© 2025 Studio_Saan. All rights reserved.',
                          style: TextStyle(
                            // 글자 색은 테마 색깔을 약간 흐리게 만듭니다.
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 앱의 헤더 부분을 만드는 함수입니다.
  Widget _buildAppHeader(BuildContext context) {
    // 배경이 될 컨테이너입니다.
    return Container(
      // 안쪽에 여백을 줍니다.
      padding: const EdgeInsets.all(24),
      // 디자인을 정합니다.
      decoration: BoxDecoration(
        // 그라데이션 배경을 사용합니다.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.indigo.withOpacity(0.6),
          ],
        ),
        // 모서리를 둥글게 만듭니다.
        borderRadius: BorderRadius.circular(24),
        // 그림자 효과를 줍니다.
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      // 위젯들을 세로로 나열합니다.
      child: Column(
        children: [
          // 달 아이콘입니다.
          Icon(
            Icons.brightness_3,
            color: Colors.white,
            size: 48,
          ),
          // 아이콘 아래에 공간을 줍니다.
          const SizedBox(height: 16),
          // 앱 이름 텍스트입니다.
          Text(
            'Lioluna',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 이름 아래에 공간을 줍니다.
          const SizedBox(height: 8),
          // 부제목 텍스트입니다.
          Text(
            '달의 비밀을 탐구하는 앱',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 일반적인 정보 카드를 만드는 함수입니다.
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    // Builder는 context를 다시 가져와서 위젯을 만들어주는 위젯입니다.
    return Builder(
      builder: (context) {
        // 카드의 배경이 될 컨테이너입니다.
        return Container(
          // 컨테이너의 디자인을 정합니다.
          decoration: BoxDecoration(
            // 그라데이션 배경을 사용합니다.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.8),
              ],
            ),
            // 모서리를 둥글게 만듭니다.
            borderRadius: BorderRadius.circular(20),
            // 그림자 효과를 줍니다.
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          // ListTile은 정보를 리스트 형태로 보여주는 편리한 위젯입니다.
          child: ListTile(
            // 리스트의 여백을 정합니다.
            contentPadding: const EdgeInsets.all(20),
            // 리스트 왼쪽에 들어갈 위젯입니다.
            leading: CircleAvatar(
              // 원의 반지름을 25로 정합니다.
              radius: 25,
              // 배경색은 아이콘 색깔을 흐리게 만듭니다.
              backgroundColor: iconColor.withOpacity(0.1),
              // 아이콘을 원 안에 넣어줍니다.
              child: Icon(icon, color: iconColor, size: 28),
            ),
            // 리스트의 제목 텍스트입니다.
            title: Text(
              title,
              // 제목의 디자인을 정합니다.
              style: TextStyle(
                // 글자 색깔은 테마에 맞춥니다.
                color: Theme.of(context).textTheme.titleLarge?.color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            // 리스트의 부제목 텍스트입니다.
            subtitle: Text(
              subtitle,
              // 부제목의 디자인을 정합니다.
              style: TextStyle(
                // 글자 색깔은 테마에 맞춥니다.
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                // 줄 간격을 약간 넓힙니다.
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }
}