
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.
import 'package:intl/intl.dart'; // 날짜와 시간을 예쁘게 보여주는 라이브러리를 가져와요.
import '../services/astro_state.dart'; // 별자리 계산과 관련된 우리 앱의 기능을 가져와요.
import '../services/astro_calculator.dart'; // 별자리 계산 관련 도구를 가져와요.

// 달의 현재 상태를 보여주는 예쁜 카드를 만드는 위젯이에요.
class MoonPhaseCard extends StatelessWidget {
  // 이 카드는 별자리 정보를 가지고 있어야 해요.
  final AstroState provider;

  // 카드를 만들 때 별자리 정보를 꼭 받아야 해요.
  const MoonPhaseCard({super.key, required this.provider});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 카드를 담을 상자를 만들어요.
    return Container(

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
      // 카드 안에 들어갈 내용(아이콘, 글자 등)을 설정해요.
      child: ListTile(
        contentPadding: const EdgeInsets.all(15), // 내용물 주변에 모든 방향으로 15만큼 여백을 줘요.
        // 왼쪽에 달 위상 이모티콘을 보여줄 공간을 만들어요.
        leading: SizedBox(
          width: 60, // 너비 60
          height: 60, // 높이 60
          // 공간의 가운데에 이모티콘을 놓아요.
          child: Center(
            child: Text(
              AstroCalculator().getMoonPhaseEmoji(provider.moonPhase), // 달의 위상에 따른 이모티콘을 가져와요.
              style: const TextStyle(fontSize: 40), // 이모티콘 크기를 40으로 해요.
            ),
          ),
        ),
        // 이모티콘 오른쪽에 글자들을 세로로 쌓아서 보여줘요.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 글자들을 왼쪽부터 시작하도록 정렬해요.
          mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 공간을 차지하게 해요.
          children: [
            // 'Moon Phase' 제목을 보여줘요.
            Text(
              'Moon Phase', // '달의 위상'이라는 제목을 써요.
              style: TextStyle(
                color: Colors.white, // 글자색은 하얀색
                fontSize: 18,
                fontWeight: FontWeight.w600, // 글자를 살짝 두껍게 만들어요.
              ),
            ),
            // 달의 현재 상태를 보여주는 글자를 써요.
            Text(
              AstroCalculator().getMoonPhaseNameOnly(provider.moonPhase), // 별자리 정보에서 달의 현재 상태를 가져와요.
              style: const TextStyle(color: Colors.white, fontSize: 18), // 하얀색, 크기 18
            ),
            const SizedBox(height: 4), // 내용과 다음 내용 사이에 작은 공간을 만들어요.
            // 다음 달의 상태가 언제인지 보여주는 글자를 써요.
            Text(
              '다음 상태 : ${provider.nextSignTime != null ? DateFormat('MM월 dd일 HH:mm').format(provider.nextSignTime!) : 'N/A'}',
              style: const TextStyle(color: Colors.white, fontSize: 16), // 하얀색, 크기 16
            ),
          ],
        ),
      ),
    );
  }
}
