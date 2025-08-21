// voc_info_card.dart
import 'package:flutter/material.dart'; // 플러터의 기본 디자인 라이브러리를 가져와요.

// 정보를 보여주는 예쁜 카드를 만드는 위젯이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class VocInfoCard extends StatelessWidget {
  // icon 파라미터를 완전히 제거했어요. (이제 아이콘 대신 이모지를 직접 받을 거예요)
  final String title; // 카드의 제목을 저장하는 상자예요.
  final Widget subtitleWidget; // 제목 아래에 들어갈 내용(글자나 다른 위젯)을 저장하는 상자예요.
  final Color iconColor; // 아이콘의 색깔을 저장하는 상자예요. (지금은 사용되지 않지만, 나중에 쓸 수도 있어요)
  // 새로운 변수: 동적으로 아이콘 이모지를 전달받기 위한 상자예요.
  final String cardIcon; 

  // 카드를 만들 때 필요한 정보들을 꼭 받아야 해요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const VocInfoCard({
    super.key,
    required this.title, // 제목은 꼭 필요해요.
    required this.subtitleWidget, // 부제목 위젯도 꼭 필요해요.
    required this.iconColor, // 아이콘 색상도 꼭 필요해요.
    required this.cardIcon, // 아이콘 이모지를 꼭 받도록 변경되었어요.
  });

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 카드를 담을 상자를 만들어요. Container는 상자 같은 위젯이에요.
    return Container(
      // 상자를 예쁘게 꾸며줘요. decoration은 꾸미는 도구예요.
      decoration: BoxDecoration(
        // 배경색을 두 가지 색이 섞이도록 만들어요. LinearGradient는 색깔이 자연스럽게 변하는 효과를 줘요.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 왼쪽 위에서 시작해서
          end: Alignment.bottomRight, // 오른쪽 아래로 색이 변해요.
          colors: [
            Theme.of(context).cardColor, // 앱의 기본 카드 색상을 사용해요.
            Theme.of(context).cardColor.withOpacity(0.8), // 기본 카드 색상을 살짝 투명하게 만들어요. (80% 투명도)
          ],
        ),
        // 모서리를 둥글게 깎아줘요. BorderRadius.circular는 모서리를 둥글게 만드는 도구예요.
        borderRadius: BorderRadius.circular(20),
        // 그림자를 만들어서 입체적으로 보이게 해요. boxShadow는 그림자를 만드는 도구예요.
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1), // 앱의 기본 그림자 색상을 아주 살짝 보이게 해요. (10% 투명도)
            blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요. 숫자가 클수록 더 부드러워져요.
            offset: const Offset(0, 5), // 그림자를 아래쪽으로 5만큼 이동시켜요. (x축으로 0, y축으로 5)
          ),
        ],
      ),
      // 카드 안에 들어갈 내용(아이콘, 글자 등)을 설정해요. child는 상자 안에 들어갈 내용이에요.
      child: ListTile(
        contentPadding: const EdgeInsets.all(9), // 내용물 주변에 모든 방향으로 9만큼 여백을 줘요. EdgeInsets.all은 모든 방향에 같은 여백을 줘요.
        leading: SizedBox(
          width: 70,
          height: 60,
          child: Center(
              child: Text(
                cardIcon, // 이제 외부에서 받은 이모지를 보여줘요.
                style: TextStyle(
                  fontSize: 35, // 원하는 크기로 조절하세요.
                ),
              ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 글자들을 왼쪽부터 시작하도록 정렬해요. (가로 정렬)
          mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 공간을 차지하게 해요. (세로 크기)
          children: [
            Text(
              title, // 'Void of Course' 같은 제목을 보여줘요.
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color, // 앱의 큰 제목 글자 색상을 사용해요.
                fontSize: 18, // 글자 크기는 18
                fontWeight: FontWeight.w600, // 글자를 살짝 두껍게 만들어요. (600은 중간 정도의 두께)
              ),
            ),
            const SizedBox(height: 3), // 제목과 부제목 사이에 작은 공간을 만들어요. SizedBox는 빈 공간을 만들어요.
            // 부제목 위젯을 보여줘요. subtitleWidget은 다른 위젯이 들어갈 수 있는 공간이에요.
            subtitleWidget,
          ],
        ),
      ),
    );
  }
}