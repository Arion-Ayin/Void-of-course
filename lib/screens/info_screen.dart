// 플러터의 기본 디자인 라이브러리를 가져와요. 화면에 보이는 것들을 만들 때 필요해요.
import 'package:flutter/material.dart';

// 우리가 만든 정보 카드 위젯을 가져와요. InfoCard는 다른 파일에 있어요.
import '../widgets/info_card.dart';

// 앱의 정보를 보여주는 화면이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class InfoScreen extends StatelessWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const InfoScreen({super.key});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 화면의 전체적인 구조를 짜요. Scaffold는 기본적인 앱 디자인을 제공하는 위젯이에요.
    return Scaffold(
      // 화면 상단의 앱 바(제목 바)예요. AppBar는 앱의 맨 위에 있는 막대기예요.
      appBar: AppBar(
        // 제목 부분에 아이콘과 글자를 가로로 나란히 놓아요. Row는 위젯들을 가로로 나란히 놓을 때 사용해요.
        title: Row(
          children: [
            // 정보 아이콘이에요. Icon은 그림 아이콘을 보여줘요.
            Icon(
              Icons.info_outline, // 정보 아이콘 모양이에요.
              color: Theme.of(context).colorScheme.primary, // 앱 테마의 기본 색깔을 사용해요. (예: 파란색)
              size: 24, // 아이콘 크기는 24
            ),
            const SizedBox(width: 8), // 아이콘과 글자 사이에 작은 공간을 만들어요. SizedBox는 빈 공간을 만들어요.
            // '정보'라는 제목을 써요. Text는 글자를 보여줘요.
            Text(
              '정보',
              style: TextStyle(
                // 현재 테마가 다크 모드인지에 따라 글자색을 정해요.
                // Theme.of(context).brightness == Brightness.dark는 지금 화면이 어두운 모드인지 물어보는 거예요.
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white // 어두운 모드면 하얀색 글자
                    : Colors.black87, // 아니면 거의 검은색 글자
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // 앱 바의 배경색을 테마에 맞게 설정해요.
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // 앱 바의 글자/아이콘 색을 테마에 맞게 설정해요.
        elevation: Theme.of(context).appBarTheme.elevation, // 앱 바의 그림자 높이를 테마에 맞게 설정해요. (높을수록 그림자가 진해져요)
      ),
      // 화면의 주요 내용이 들어가는 부분이에요. body는 Scaffold의 몸통 부분이에요.
      body: Container(
        width: double.infinity, // 너비를 화면 끝까지 채워요. (double.infinity는 무한대라는 뜻이에요)
        height: double.infinity, // 높이를 화면 끝까지 채워요.
        // 화면 배경을 예쁘게 꾸며줘요. decoration은 꾸미는 도구예요.
        decoration: BoxDecoration(
          // 배경색을 위에서 아래로 변하게 만들어요. LinearGradient는 색깔이 자연스럽게 변하는 효과를 줘요.
          gradient: LinearGradient(
            begin: Alignment.topCenter, // 위쪽 가운데에서 시작해서
            end: Alignment.bottomCenter, // 아래쪽 가운데로 색이 변해요.
            colors: [
              Theme.of(context).colorScheme.background, // 앱 테마의 배경색 (예: 하얀색 또는 어두운 회색)
              Theme.of(context).colorScheme.surface, // 앱 테마의 표면색 (예: 하얀색 또는 더 어두운 회색)
            ],
          ),
        ),
        // 휴대폰의 상태표시줄 같은 시스템 UI를 피해서 내용을 보여줘요. SafeArea는 화면의 안전한 영역에 위젯을 배치해요.
        child: SafeArea(
          // 내용이 길어지면 스크롤 할 수 있게 만들어요. SingleChildScrollView는 내용이 화면을 넘어가면 스크롤이 가능하게 해요.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0), // 모든 방향으로 20만큼 여백을 줘요. EdgeInsets.all은 모든 방향에 같은 여백을 줘요.
            // 화면에 보이는 위젯들을 세로로 차곡차곡 쌓아요. Column은 위젯들을 세로로 쌓을 때 사용해요.
            child: Column(
              children: [
                // 1. 앱의 헤더(머리글) 부분을 넣어요.
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.withOpacity(0.8),
                        Colors.indigo.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.brightness_3, color: Colors.white, size: 48), // 달 모양 아이콘
                      const SizedBox(height: 16),
                      const Text(
                        'Void of Course',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '보이드 오브 코스 계산기',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30), // 헤더와 다음 내용 사이에 공간을 만들어요.

                // 2. '우리는 누구인가요?' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.people, // 사람 아이콘
                  title: '우리는 누구인가요?',
                  subtitle:
                      '• 스튜디오 사안의 사명 : \n사자의 눈으로 세상을 헤아립니다.\n', // 여러 줄의 글자
                  iconColor: Colors.amber, // 아이콘 색깔은 호박색
                ),
                const SizedBox(height: 20), // 카드와 카드 사이에 공간을 만들어요.

                // 3. '누구에게 유용한가요?' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.timer_sharp, // 시계 아이콘
                  title: '누구에게 유용한가요?',
                  subtitle:
                      '• 간단한 택일이 필요하신 분들\n'
                      '• 보이드 오브 코스 계산이 필요한 분들\n'
                      '• 행동의 지표성이 필요한 분들\n',
                  iconColor: Colors.green, // 아이콘 색깔은 초록색
                ),
                const SizedBox(height: 20), // 카드와 카드 사이에 공간을 만들어요.

                // 4. '왜 이 앱을 만들었나요?' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.app_shortcut, // 앱 아이콘
                  title: '왜 이 앱을 만들었나요?',
                  subtitle:
                      '• 간단하게 택일하고 싶었기에\n'
                      '• 누구나 손쉽게 이 정보들에 \n  접근 가능하면 좋겠다는 마음에\n',
                  iconColor: Colors.purple, // 아이콘 색깔은 보라색
                ),
                const SizedBox(height: 20), // 카드와 카드 사이에 공간을 만들어요.

                // 5. '업데이트 로그' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.login, // 로그인 아이콘 (업데이트 기록을 의미)
                  title: '업데이트 로그',
                  subtitle:
                      'v1.0.0 (2025-08-14)\n'
                      '• 초기 릴리즈\n'
                      '• 달 위상 계산 기능\n'
                      '• 보이드 오브 코스 계산\n',
                  iconColor: Colors.orange, // 아이콘 색깔은 주황색
                ),
                const SizedBox(height: 30), // 카드와 저작권 텍스트 사이에 공간을 만들어요.

                // 6. 저작권 텍스트를 넣어요.
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor, // 앱의 카드 색상을 배경색으로 사용해요.
                    borderRadius: BorderRadius.circular(16), // 모서리를 둥글게 깎아줘요.
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).shadowColor.withOpacity(0.1), // 앱의 그림자 색상을 살짝 투명하게 만들어요.
                        blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요.
                        offset: const Offset(0, 5), // 그림자를 아래쪽으로 5만큼 이동시켜요.
                      ),
                    ],
                  ),
                  child: Text(
                    '© 2025 Studio_Saan. All rights reserved.', // 저작권 문구예요.
                    style: TextStyle(
                      // 글자색을 앱의 기본 텍스트 색상에서 살짝 투명하게 만들어요.
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      fontSize: 12, // 글자 크기는 12
                      fontStyle: FontStyle.italic, // 글자를 기울여서 보여줘요.
                    ),
                    textAlign: TextAlign.center, // 글자를 가운데 정렬해요.
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}