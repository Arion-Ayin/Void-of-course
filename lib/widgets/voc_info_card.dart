import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../services/astro_state.dart'; 

class VocInfoCard extends StatelessWidget {
  // 'AstroState' 타입의 'provider' 변수를 선언합니다. 이 변수를 통해 상태에 접근할 수 있습니다.
  final AstroState provider;

  // 'VocInfoCard'의 생성자입니다. 'key'와 'provider'를 필수로 받습니다.
  const VocInfoCard({
    super.key,
    required this.provider,
  });

  // 'DateTime' 객체를 '월 일 시:분' 형식의 문자열로 변환하는 private 메서드입니다.
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';                    // 만약 'dateTime'이 null이면 'N/A'를 반환합니다.
    return DateFormat('MM/dd HH:mm').format(dateTime); // 'DateFormat'을 사용하여 지정된 형식으로 날짜와 시간을 변환하고 반환합니다.
  }

  @override
  Widget build(BuildContext context) {
    final vocStart = provider.vocStart;  // 'provider'에서 보이드 시작 시간('vocStart')을 가져옵니다
    final vocEnd = provider.vocEnd; // 'provider'에서 보이드 종료 시간('vocEnd')을 가져옵니다.
    final now = DateTime.now(); // 현재 시간을 가져옵니다.
    final selectedDate = provider.selectedDate; // 'provider'에서 선택된 날짜('selectedDate')를 가져옵니다.

    // 'isVocNow' 변수를 선언하고 초기값을 false로 설정합니다. 현재 시간이 보이드 구간인지 확인합니다.
    bool isVocNow = false;
    // 'vocStart'와 'vocEnd'가 모두 null이 아닐 때만 확인 로직을 실행합니다.
    if (vocStart != null && vocEnd != null) {
      // 현재 시간이 보이드 시작 시간 이후이고 종료 시간 이전이면 'isVocNow'를 true로 설정합니다.
      isVocNow = now.isAfter(vocStart) && now.isBefore(vocEnd);
    }

    // 'doesSelectedDateHaveVoc' 변수를 선언하고 초기값을 false로 설정합니다. 선택된 날짜에 보이드가 포함되어 있는지 확인합니다.
    bool doesSelectedDateHaveVoc = false;
    // 'vocStart'와 'vocEnd'가 모두 null이 아닐 때만 확인 로직을 실행합니다.
    if (vocStart != null && vocEnd != null) {
      // 선택된 날짜의 자정('00:00:00')을 기준으로 'selectedDayStart'를 생성합니다.
      final selectedDayStart =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      // 'selectedDayStart'에 하루를 더하여 'selectedDayEnd'를 생성합니다(다음 날 자정).
      final selectedDayEnd = selectedDayStart.add(const Duration(days: 1));

      // 보이드 시작 시간이 'selectedDayEnd' 이전이고, 보이드 종료 시간이 'selectedDayStart' 이후이면
      // 즉, 보이드 기간이 선택된 날짜와 겹치면 'doesSelectedDateHaveVoc'를 true로 설정합니다.
      if (vocStart.isBefore(selectedDayEnd) && vocEnd.isAfter(selectedDayStart)) {
        doesSelectedDateHaveVoc = true;
      }
    }

    // 보이드 상태에 따라 표시할 텍스트('vocStatusText'), 아이콘('vocIcon'), 색상('vocColor')을 선언합니다.
    String vocStatusText;
    String vocIcon;
    Color vocColor;

    // 'isVocNow'가 true(현재가 보이드 시간)인 경우
    if (isVocNow) {
      vocStatusText = "There's a void Now"; // 상태 텍스트를 '보이드 입니다'로 설정합니다.
      vocIcon = '🚫'; // 아이콘을 🚫로 설정합니다.
      vocColor = Colors.red; // 색상을 빨간색으로 설정합니다.
    } 
    // 'isVocNow'가 false이고 'doesSelectedDateHaveVoc'가 true(선택된 날짜에 보이드가 있음)인 경우
    else if (doesSelectedDateHaveVoc) {
      vocStatusText = "There's a void today"; // 상태 텍스트를 '금일 보이드가 있습니다.'로 설정합니다.
      vocIcon = '🔔'; // 아이콘을 🔔로 설정합니다.
      vocColor = Colors.orange; // 색상을 주황색으로 설정합니다.
    } 
    // 위 두 조건 모두 해당하지 않는 경우(보이드가 아닌 경우)
    else {
      vocStatusText = "It's not a void"; // 상태 텍스트를 '보이드가 아닙니다'로 설정합니다.
      vocIcon = '✅'; // 아이콘을 ✅로 설정합니다.
      vocColor = Colors.green; // 색상을 초록색으로 설정합니다.
    }

    // UI를 구성하는 'Container' 위젯을 반환합니다.
    return Container(
      // 'Container'의 장식(decoration)을 설정합니다.
      decoration: BoxDecoration(
        // 배경에 그라데이션 효과를 적용합니다.
        gradient: LinearGradient(
          begin: Alignment.topLeft, // 그라데이션 시작점을 왼쪽 상단으로 설정합니다.
          end: Alignment.bottomRight, // 그라데이션 종료점을 오른쪽 하단으로 설정합니다.
          colors: [
            Theme.of(context).cardColor, // 현재 테마의 카드 색상을 첫 번째 색상으로 사용합니다.
            Theme.of(context).cardColor.withOpacity(0.8), // 카드 색상에 투명도를 0.8로 적용하여 두 번째 색상으로 사용합니다.
          ],
        ),
        // 모서리를 둥글게 만듭니다.
        borderRadius: BorderRadius.circular(20),
        // 그림자 효과를 추가합니다.
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1), // 그림자 색상에 투명도를 0.1로 적용합니다.
            blurRadius: 10, // 그림자의 흐림 정도를 10으로 설정합니다.
            offset: const Offset(0, 5), // 그림자의 위치를 y축으로 5만큼 아래로 이동합니다.
          ),
        ],
      ),
      // 'ListTile' 위젯을 사용하여 목록 항목 형태의 UI를 만듭니다.
      child: ListTile(
        contentPadding: const EdgeInsets.all(5), // 'ListTile'의 내부 여백을 8로 설정합니다.
        leading: SizedBox( // 'ListTile'의 왼쪽에 아이콘을 담을 'SizedBox'를 배치합니다.
          width: 70, // 너비를 60으로 설정합니다.
          height: 70, // 높이를 60으로 설정합니다.
          child: Center( // 'SizedBox' 내에서 자식 위젯을 중앙에 정렬합니다.
            child: Text( // 'vocIcon' 변수의 값을 표시하는 'Text' 위젯입니다.
              vocIcon,
              style: const TextStyle(
                fontSize: 40, // 글자 크기를 40으로 설정합니다.
              ),
            ),
          ),
        ),
        title: Column( // 'ListTile'의 제목 영역에 세로로 위젯들을 배치하는 'Column'을 사용합니다.
          crossAxisAlignment: CrossAxisAlignment.start, // 자식 위젯들을 왼쪽으로 정렬합니다.
          mainAxisSize: MainAxisSize.min, // 'Column'의 크기를 자식 위젯의 최소 크기에 맞춥니다.
          children: [
            Text( // 'Void of Course'라는 제목 텍스트를 표시합니다.
              'Void of Course',
              style: TextStyle(
                color: Theme.of(context).textTheme.titleLarge?.color, // 현재 테마의 제목 글자 색상을 사용합니다.
                fontSize: 18, // 글자 크기를 18로 설정합니다.
                fontWeight: FontWeight.w600, // 글자 두께를 굵게 설정합니다.
              ),
            ),
            const SizedBox(height: 1), // 위젯 사이에 1픽셀의 공간을 추가합니다.
            Text( // 보이드의 시작과 종료 시간을 표시하는 텍스트입니다.
              'Start : ${_formatDateTime(provider.vocStart)}\n' // 시작 시간을 형식에 맞게 표시합니다.
              'End   : ${_formatDateTime(provider.vocEnd)}', // 종료 시간을 형식에 맞게 표시합니다.
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color, // 현재 테마의 본문 글자 색상을 사용합니다.
                fontSize: 17, // 글자 크기를 17로 설정합니다.
                fontWeight: FontWeight.w600, // 글자 두께를 굵게 설정합니다.
              ),
            ),
            const SizedBox(height: 1), // 위젯 사이에 1픽셀의 공간을 추가합니다.
            Text( // 보이드 상태 텍스트를 표시합니다.
              vocStatusText,
              style: TextStyle(
                color: vocColor, // 'vocColor' 변수의 색상을 사용합니다.
                fontSize: 19, // 글자 크기를 19로 설정합니다.
                fontWeight: FontWeight.w900, // 글자 두께를 매우 굵게 설정합니다.
              ),
            ),
          ],
        ),
      ),
    );
  }
}