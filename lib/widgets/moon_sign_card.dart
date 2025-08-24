import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/astro_state.dart';
import '../services/astro_calculator.dart';

// 달이 어떤 별자리에 있는지 보여주는 카드를 만드는 위젯이에요.
class MoonSignCard extends StatelessWidget {
  // 이 카드는 별자리 정보가 필요해요.
  final AstroState provider;
  // 다음 별자리로 바뀌는 시간 정보도 필요해요.
  final String nextSignTimeText;

  // 카드를 만들 때 이 정보들을 꼭 받아야 해요.
  const MoonSignCard({super.key, required this.provider, required this.nextSignTimeText});

  // 별자리 이름에 맞는 이모티콘(그림 아이콘)을 찾아주는 함수예요.
  String getZodiacEmoji(String sign) {
    // 만약 별자리 이름이 'Aries'(양자리)이면, 양자리 이모티콘을 돌려줘요.
    switch (sign) {
      case 'Aries':
        return '♈'; // 양자리
      case 'Taurus':
        return '♉'; // 황소자리
      case 'Gemini':
        return '♊'; // 쌍둥이자리
      case 'Cancer':
        return '♋'; // 게자리
      case 'Leo':
        return '♌'; // 사자자리
      case 'Virgo':
        return '♍'; // 처녀자리
      case 'Libra':
        return '♎'; // 천칭자리
      case 'Scorpio':
        return '♏'; // 전갈자리
      case 'Sagittarius':
        return '♐'; // 사수자리
      case 'Capricorn':
        return '♑'; // 염소자리
      case 'Aquarius':
        return '♒'; // 물병자리
      case 'Pisces':
        return '♓'; // 물고기자리
      default:
        return '❔'; // 아는 별자리가 없으면 물음표를 보여줘요.
    }
  }

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 다음 별자리 시간 텍스트를 포맷팅합니다.
    final nextSignTime = provider.nextSignTime;
    final formattedNextSignTime = nextSignTime != null 
        ? DateFormat('MM월 dd일 HH:mm').format(nextSignTime)
        : 'N/A';

    // 카드를 담을 상자를 만들어요.
    return Container(
      // 상자를 예쁘게 꾸며줘요.
      decoration: BoxDecoration(
        // 배경색을 두 가지 색이 섞이도록 만들어요.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 왼쪽 위에서 시작해서
          end: Alignment.bottomRight, // 오른쪽 아래로 색이 변해요.
          colors: [
            Theme.of(context).cardColor, // 앱의 기본 카드 색상을 사용해요.
            Theme.of(context).cardColor.withOpacity(0.8), // 기본 카드 색상을 살짝 투명하게 만들어요.
          ],
        ),
        // 모서리를 둥글게 깎아줘요.
        borderRadius: BorderRadius.circular(20),
        // 그림자를 만들어서 입체적으로 보이게 해요.
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1), // 앱의 기본 그림자 색상을 아주 살짝 보이게 해요.
            blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요.
            offset: const Offset(0, 5), // 그림자를 아래쪽으로 5만큼 이동시켜요.
          ),
        ],
      ),
      // 카드 안에 들어갈 내용(아이콘, 글자 등)을 설정해요.
      child: ListTile(
        contentPadding: const EdgeInsets.all(8), // 내용물 주변에 모든 방향으로 20만큼 여백을 줘요.
        // 왼쪽에 별자리 이모티콘을 보여줄 공간을 만들어요.
        leading: SizedBox(
          width: 60, // 너비 60
          height: 60, // 높이 60
          // 공간의 가운데에 이모티콘을 놓아요.
          child: Center(
            child: Text(
              getZodiacEmoji(provider.moonInSign), // 별자리 이름으로 이모티콘을 찾아서 보여줘요.
              style: const TextStyle(fontSize: 44), // 이모티콘 크기를 40으로 해요.
            ),
          ),
        ),
        // 이모티콘 오른쪽에 글자들을 세로로 쌓아서 보여줘요.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // 글자들을 왼쪽부터 시작하도록 정렬해요.
          mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 공간을 차지하게 해요.
          children: [
            // 달이 있는 별자리 이름을 보여줘요.
            Text(
              'Moon in ${provider.moonInSign}', // '달은 양자리에 있어요' 처럼 보여줘요.
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color, // 앱의 큰 제목 글자 색상을 사용해요.
                fontSize: 18, // 글자 크기는 18
                fontWeight: FontWeight.w600, // 글자를 살짝 두껍게 만들어요.
              ),
            ),
            // 다음 별자리로 바뀌는 시간을 보여줘요.
            Text(
              '다음 싸인 : ${formattedNextSignTime}', // 포맷팅된 시간을 보여줘요.
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color, // 앱의 보통 글자 색상을 사용해요.
                fontSize: 17, // 글자 크기는 14
                fontWeight: FontWeight.w900, // 글자를 매우 두껍게 만들어요.
              ),
            ),
          ],
        ),
      ),
    );
  }
}