import 'package:flutter/material.dart'; // 플러터의 기본 디자인 라이브러리를 가져와요.
import '../widgets/app_header.dart'; // 우리가 만든 앱 헤더 위젯을 가져와요.
import '../widgets/copyright_text.dart'; // 우리가 만든 저작권 텍스트 위젯을 가져와요.
import '../widgets/info_card.dart'; // 우리가 만든 정보 카드 위젯을 가져와요.

// 앱의 정보를 보여주는 화면이에요.
class InfoScreen extends StatelessWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요.
  const InfoScreen({super.key});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 화면의 전체적인 구조를 짜요.
    return Scaffold(
      // 화면 상단의 앱 바(제목 바)예요.
      appBar: AppBar(
        // 제목 부분에 아이콘과 글자를 가로로 나란히 놓아요.
        title: Row(
          children: [
            // 정보 아이콘이에요.
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary, // 앱 테마의 기본 색깔을 사용해요.
              size: 24, // 아이콘 크기는 24
            ),
            const SizedBox(width: 8), // 아이콘과 글자 사이에 작은 공간을 만들어요.
            // '정보'라는 제목을 써요.
            Text(
              '정보',
              style: TextStyle(
                // 현재 테마가 다크 모드인지에 따라 글자색을 정해요.
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // 앱 바의 배경색을 테마에 맞게 설정해요.
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // 앱 바의 글자/아이콘 색을 테마에 맞게 설정해요.
        elevation: Theme.of(context).appBarTheme.elevation, // 앱 바의 그림자 높이를 테마에 맞게 설정해요.
      ),
      // 화면의 주요 내용이 들어가는 부분이에요.
      body: Container(
        width: double.infinity, // 너비를 화면 끝까지 채워요.
        height: double.infinity, // 높이를 화면 끝까지 채워요.
        // 화면 배경을 예쁘게 꾸며줘요.
        decoration: BoxDecoration(
          // 배경색을 위에서 아래로 변하게 만들어요.
          gradient: LinearGradient(
            begin: Alignment.topCenter, // 위쪽 가운데에서 시작해서
            end: Alignment.bottomCenter, // 아래쪽 가운데로 색이 변해요.
            colors: [
              Theme.of(context).colorScheme.background, // 앱 테마의 배경색
              Theme.of(context).colorScheme.surface, // 앱 테마의 표면색
            ],
          ),
        ),
        // 휴대폰의 상태표시줄 같은 시스템 UI를 피해서 내용을 보여줘요.
        child: SafeArea(
          // 내용이 길어지면 스크롤 할 수 있게 만들어요.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0), // 모든 방향으로 20만큼 여백을 줘요.
            // 화면에 보이는 위젯들을 세로로 차곡차곡 쌓아요.
            child: Column(
              children: [
                // 1. 앱의 헤더(머리글) 부분을 넣어요.
                const AppHeader(),
                const SizedBox(height: 30), // 헤더와 다음 내용 사이에 공간을 만들어요.

                // 2. '우리는 누구인가요?' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.people,
                  title: '우리는 누구인가요?',
                  subtitle:
                      '• 스튜디오 사안의 사명 : \n사자의 눈으로 세상을 헤아립니다.\n',
                  iconColor: Colors.amber,
                ),
                const SizedBox(height: 20), // 카드와 카드 사이에 공간을 만들어요.

                // 3. '누구에게 유용한가요?' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.timer_sharp,
                  title: '누구에게 유용한가요?',
                  subtitle:
                      '• 간단한 택일이 필요하신 분들\n'
                      '• 보이드 오브 코스 계산이 필요한 분들\n'
                      '• 행동의 지표성이 필요한 분들\n',
                  iconColor: Colors.green,
                ),
                const SizedBox(height: 20), // 카드와 카드 사이에 공간을 만들어요.

                // 4. '왜 이 앱을 만들었나요?' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.app_shortcut,
                  title: '왜 이 앱을 만들었나요?',
                  subtitle:
                      '• 간단하게 택일하고 싶었기에\n'
                      '• 누구나 손쉽게 이 정보들에 \n  접근 가능하면 좋겠다는 마음에\n',
                  iconColor: Colors.purple,
                ),
                const SizedBox(height: 20), // 카드와 카드 사이에 공간을 만들어요.

                // 5. '업데이트 로그' 정보를 보여주는 카드예요.
                const InfoCard(
                  icon: Icons.login,
                  title: '업데이트 로그',
                  subtitle:
                      'v1.0.0 (2025-08-14)\n'
                      '• 초기 릴리즈\n'
                      '• 달 위상 계산 기능\n'
                      '• 보이드 오브 코스 계산\n',
                  iconColor: Colors.orange,
                ),
                const SizedBox(height: 30), // 카드와 저작권 텍스트 사이에 공간을 만들어요.

                // 6. 저작권 텍스트를 넣어요.
                const CopyrightText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
