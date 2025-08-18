
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.

// 날짜를 보여주고 바꿀 수 있는 위젯이에요.
class DateSelector extends StatelessWidget {
  // 날짜를 보여주는 입력창을 다루는 컨트롤러예요.
  final TextEditingController dateController;
  // 달력을 보여주는 함수예요.
  final VoidCallback showCalendar;
  // 날짜를 하루 뒤로 바꾸는 함수예요.
  final VoidCallback onNextDay;
  // 날짜를 하루 앞으로 바꾸는 함수예요.
  final VoidCallback onPreviousDay;

  // 이 위젯을 만들 때 필요한 것들을 꼭 받아야 해요.
  const DateSelector({
    super.key,
    required this.dateController, // 날짜 컨트롤러는 꼭 필요해요.
    required this.showCalendar, // 달력 보여주는 함수도 꼭 필요해요.
    required this.onNextDay, // 다음 날로 가는 함수도 꼭 필요해요.
    required this.onPreviousDay, // 이전 날로 가는 함수도 꼭 필요해요.
  });

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 내용물을 담을 상자를 만들어요.
    return Container(
      // 상자 안쪽에 세로로 12, 가로로 16만큼 여백을 줘요.
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
      // 상자를 예쁘게 꾸며줘요.
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // 앱의 기본 카드 색상을 배경색으로 사용해요.
        borderRadius: BorderRadius.circular(16), // 모서리를 둥글게 깎아줘요.
        boxShadow: const [ // 그림자를 만들어서 입체적으로 보이게 해요.
          BoxShadow(color: Colors.black12, blurRadius: 10), // 검은색 그림자를 살짝 흐리게 만들어요.
        ],
      ),
      // 내용물들을 가로로 나란히 놓아요.
      child: Row(
        children: [
          // 왼쪽 화살표 버튼이에요.
          IconButton(
            icon: const Icon(Icons.arrow_back_ios), // 왼쪽 화살표 모양 아이콘
            onPressed: onPreviousDay, // 버튼을 누르면 이전 날로 가는 함수를 실행해요.
            color: Theme.of(context).iconTheme.color, // 앱의 기본 아이콘 색상을 사용해요.
          ),
          // 가운데 날짜가 보이는 부분을 만들어요. 공간을 꽉 채우도록 해요.
          Expanded(
            // 글자를 입력하는 칸이에요.
            child: TextField(
              controller: dateController, // 위에서 받은 날짜 컨트롤러를 연결해요.
              readOnly: true, // 사용자가 직접 글자를 수정할 수는 없어요.
              decoration: InputDecoration(
                border: InputBorder.none, // 테두리는 없애요.
                hintText: 'YYYY-MM-DD', // 아무것도 없을 때 보여줄 안내 글자예요.
                hintStyle: TextStyle(
                  // 안내 글자의 스타일을 정해요.
                  color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5),
                ),
              ),
              style: TextStyle(
                // 실제 날짜 글자의 스타일을 정해요.
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
              keyboardType: TextInputType.number, // 숫자 키보드를 보여줘요 (여기서는 직접 입력은 안돼요).
              textAlign: TextAlign.center, // 글자를 가운데 정렬해요.
              onTap: showCalendar, // 이 부분을 누르면 달력을 보여주는 함수를 실행해요.
            ),
          ),
          // 오른쪽 화살표 버튼이에요.
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios), // 오른쪽 화살표 모양 아이콘
            onPressed: onNextDay, // 버튼을 누르면 다음 날로 가는 함수를 실행해요.
            color: Theme.of(context).iconTheme.color, // 앱의 기본 아이콘 색상을 사용해요.
          ),
        ],
      ),
    );
  }
}
