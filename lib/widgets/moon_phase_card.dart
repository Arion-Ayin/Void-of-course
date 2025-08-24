// 플러터의 디자인 라이브러리를 가져와요. 화면에 보이는 것들을 만들 때 필요해요.
import 'package:flutter/material.dart';
// 날짜와 시간을 예쁘게 보여주는 라이브러리를 가져와요. (예: 2025년 8월 14일)
import 'package:intl/intl.dart';
// 별자리 계산과 관련된 우리 앱의 중요한 정보들을 가져와요. (AstroState)
import '../services/astro_state.dart';
// 별자리 계산 관련 도구들을 가져와요. (AstroCalculator)
import '../services/astro_calculator.dart';

// 달의 현재 상태를 보여주는 예쁜 카드를 만드는 위젯이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class MoonPhaseCard extends StatelessWidget {
  // 이 카드는 별자리 정보를 가지고 있어야 해요. provider라는 이름의 상자에 넣어둘 거예요.
  final AstroState provider;

  // 카드를 만들 때 별자리 정보를 꼭 받아야 해요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const MoonPhaseCard({super.key, required this.provider});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 카드를 담을 상자를 만들어요. Container는 상자 같은 위젯이에요.
    return Container(

      // 상자를 예쁘게 꾸며줘요. decoration은 꾸미는 도구예요.
      decoration: BoxDecoration(
        // 배경색을 보라색에서 남색으로 변하게 만들어요. LinearGradient는 색깔이 자연스럽게 변하는 효과를 줘요.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 왼쪽 위에서 시작해서
          end: Alignment.bottomRight, // 오른쪽 아래로 색이 변해요.
          colors: [
            Colors.purple.withOpacity(0.8), // 보라색 (살짝 투명하게, 0.8은 80% 투명도)
            Colors.indigo.withOpacity(0.6), // 남색 (살짝 투명하게, 0.6은 60% 투명도)
          ],
        ),
        // 모서리를 둥글게 깎아줘요. BorderRadius.circular는 모서리를 둥글게 만드는 도구예요.
        borderRadius: BorderRadius.circular(24),
        // 그림자를 만들어서 입체적으로 보이게 해요. boxShadow는 그림자를 만드는 도구예요.
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3), // 보라색 그림자 (더 투명하게, 0.3은 30% 투명도)
            blurRadius: 20, // 그림자를 부드럽게 퍼지게 해요. 숫자가 클수록 더 부드러워져요.
            offset: const Offset(0, 10), // 그림자를 아래쪽으로 10만큼 이동시켜요. (x축으로 0, y축으로 10)
          ),
        ],
      ),
      // 카드 안에 들어갈 내용(아이콘, 글자 등)을 설정해요. child는 상자 안에 들어갈 내용이에요.
      child: ListTile(
        contentPadding: const EdgeInsets.all(15), // 내용물 주변에 모든 방향으로 15만큼 여백을 줘요. EdgeInsets.all은 모든 방향에 같은 여백을 줘요.
        // 왼쪽에 달 위상 이모티콘을 보여줄 공간을 만들어요. leading은 목록의 맨 앞에 오는 위젯이에요.
        leading: SizedBox(
          width: 60, // 너비 60만큼 공간을 차지해요.
          height: 60, // 높이 60만큼 공간을 차지해요.
          // 공간의 가운데에 이모티콘을 놓아요. Center는 위젯을 가운데로 정렬해요.
          child: Center(
            child: Text(
              // AstroCalculator에게 달의 위상에 맞는 이모티콘을 가져오라고 부탁해요. provider.moonPhase는 현재 달의 위상 정보예요.
              AstroCalculator().getMoonPhaseEmoji(provider.moonPhase),
              style: const TextStyle(fontSize: 40), // 이모티콘 크기를 40으로 해요. TextStyle은 글자의 모양을 정해요.
            ),
          ),
        ),
        // 이모티콘 오른쪽에 글자들을 세로로 쌓아서 보여줘요. title은 목록의 제목 부분이에요.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 글자들을 왼쪽부터 시작하도록 정렬해요. (가로 정렬)
          mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 공간을 차지하게 해요. (세로 크기)
          children: [
            // 'Moon Phase' 제목을 보여줘요.
            Text(
              'Moon Phase', // '달의 위상'이라는 제목을 써요.
              style: TextStyle(
                color: Colors.white, // 글자색은 하얀색
                fontSize: 22, // 글자 크기는 18
                fontWeight: FontWeight.w600, // 글자를 살짝 두껍게 만들어요. (600은 중간 정도의 두께)
              ),
            ),
            // 달의 현재 상태를 보여주는 글자를 써요.
            Text(
              // AstroCalculator에게 달의 위상 이름만 가져오라고 부탁해요. (예: 'New Moon'만)
              AstroCalculator().getMoonPhaseNameOnly(provider.moonPhase),
              style: const TextStyle(color: Colors.white, fontSize: 18), // 하얀색, 크기 18
            ),
            const SizedBox(height: 4), // 내용과 다음 내용 사이에 작은 공간을 만들어요. SizedBox는 빈 공간을 만들어요.
            // 다음 달의 상태가 언제인지 보여주는 글자를 써요.
            Text(
              // provider.nextSignTime이 비어있지 않다면(null이 아니라면),
              '다음 상태 : ${provider.nextSignTime != null 
                  // 날짜를 'MM월 dd일 HH:mm' 형식으로 예쁘게 만들어서 보여줘요.
                  ? DateFormat('MM월 dd일 HH:mm').format(provider.nextSignTime!) 
                  // 만약 비어있다면 'N/A'라고 보여줘요.
                  : 'N/A'}',
              style: const TextStyle(color: Colors.white, fontSize: 16), // 하얀색, 크기 16
            ),
          ],
        ),
      ),
    );
  }
}