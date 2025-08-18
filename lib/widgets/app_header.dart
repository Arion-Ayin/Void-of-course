
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.

// 앱의 정보 화면 맨 위에 보여줄 멋진 헤더(머리글) 위젯이에요.
class AppHeader extends StatelessWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요.
  const AppHeader({super.key});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 헤더를 담을 상자를 만들어요.
    return Container(
      padding: const EdgeInsets.all(20), // 상자 안쪽에 모든 방향으로 20만큼 여백을 줘요.
      // 상자를 예쁘게 꾸며줘요.
      decoration: BoxDecoration(
        // 배경색을 보라색에서 남색으로 변하게 만들어요.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 왼쪽 위에서 시작해서
          end: Alignment.bottomRight, // 오른쪽 아래로 색이 변해요.
          colors: [
            Colors.purple.withOpacity(0.8), // 보라색 (살짝 투명하게)
            Colors.indigo.withOpacity(0.6), // 남색 (살짝 투명하게)
          ],
        ),
        // 모서리를 둥글게 깎아줘요.
        borderRadius: BorderRadius.circular(24),
        // 그림자를 만들어서 입체적으로 보이게 해요.
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3), // 보라색 그림자 (더 투명하게)
            blurRadius: 20, // 그림자를 부드럽게 퍼지게 해요.
            offset: const Offset(0, 10), // 그림자를 아래쪽으로 10만큼 이동시켜요.
          ),
        ],
      ),
      // 내용물들을 세로로 차곡차곡 쌓아요.
      child: Column(
        children: [
          const Icon(Icons.brightness_3, color: Colors.white, size: 48), // 달 모양 아이콘을 넣어요.
          const SizedBox(height: 16), // 아이콘과 글자 사이에 공간을 만들어요.
          const Text(
            'Void of Course', // 'Void of Course'라는 제목을 써요.
            style: TextStyle(
              color: Colors.white, // 글자색은 하얀색
              fontSize: 32, // 글자 크기는 32
              fontWeight: FontWeight.bold, // 글자를 두껍게 만들어요.
            ),
          ),
          const SizedBox(height: 8), // 제목과 부제목 사이에 공간을 만들어요.
          const Text(
            '보이드 오브 코스 계산기', // '보이드 오브 코스 계산기'라는 부제목을 써요.
            style: TextStyle(color: Colors.white70, fontSize: 16), // 하얀색 (살짝 투명하게), 크기 16
          ),
        ],
      ),
    );
  }
}
