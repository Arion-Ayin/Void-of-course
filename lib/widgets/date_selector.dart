// 플러터의 디자인 라이브러리를 가져와요. 화면에 보이는 것들을 만들 때 필요해요.
import 'package:flutter/material.dart';

// 날짜를 보여주고 바꿀 수 있는 위젯이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class DateSelector extends StatelessWidget {
  // 날짜를 보여주는 입력창을 다루는 컨트롤러예요. TextEditingController는 글자를 입력하는 칸을 조종하는 도구예요.
  final TextEditingController dateController;
  // 달력을 보여주는 함수예요. VoidCallback은 아무것도 돌려주지 않고 아무것도 받지 않는 함수를 뜻해요.
  final VoidCallback showCalendar;
  // 날짜를 하루 뒤로 바꾸는 함수예요.
  final VoidCallback onNextDay;
  // 날짜를 하루 앞으로 바꾸는 함수예요.
  final VoidCallback onPreviousDay;

  // 이 위젯을 만들 때 필요한 것들을 꼭 받아야 해요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const DateSelector({
    super.key,
    required this.dateController, // 날짜 컨트롤러는 꼭 필요해요.
    required this.showCalendar, // 달력 보여주는 함수도 꼭 필요해요.
    required this.onNextDay, // 다음 날로 가는 함수도 꼭 필요해요.
    required this.onPreviousDay, // 이전 날로 가는 함수도 꼭 필요해요.
  });

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 내용물을 담을 상자를 만들어요. Container는 상자 같은 위젯이에요.
    return Container(
      // 상자 안쪽에 세로로 12, 가로로 16만큼 여백을 줘요. EdgeInsets.symmetric는 가로/세로 여백을 따로 정할 때 사용해요.
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
      // 상자를 예쁘게 꾸며줘요. decoration은 꾸미는 도구예요.
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // 앱의 기본 카드 색상을 배경색으로 사용해요.
        borderRadius: BorderRadius.circular(16), // 모서리를 둥글게 깎아줘요. (16만큼 둥글게)
        boxShadow: const [ // 그림자를 만들어서 입체적으로 보이게 해요.
          BoxShadow(color: Colors.black12, blurRadius: 10), // 검은색 그림자를 살짝 흐리게 만들어요. (black12는 12% 투명한 검은색)
        ],
      ),
      // 내용물들을 가로로 나란히 놓아요. Row는 위젯들을 가로로 나란히 놓을 때 사용해요.
      child: Row(
        children: [
          // 왼쪽 화살표 버튼이에요. IconButton은 아이콘 모양의 버튼이에요.
          IconButton(
            icon: const Icon(Icons.arrow_back_ios), // 왼쪽 화살표 모양 아이콘
            onPressed: onPreviousDay, // 버튼을 누르면 onPreviousDay 함수를 실행해요.
            color: Theme.of(context).iconTheme.color, // 앱의 기본 아이콘 색상을 사용해요.
          ),
          // 가운데 날짜가 보이는 부분을 만들어요. 공간을 꽉 채우도록 해요. Expanded는 남은 공간을 모두 차지하게 해요.
          Expanded(
            // 글자를 입력하는 칸이에요. TextField는 글자를 입력받는 위젯이에요.
            child: TextField(
              controller: dateController, // 위에서 받은 dateController를 연결해요. 이 컨트롤러로 날짜를 보여주고 바꿀 수 있어요.
              readOnly: true, // 사용자가 직접 글자를 수정할 수는 없어요. (읽기 전용)
              decoration: InputDecoration(
                border: InputBorder.none, // 테두리는 없애요. (깔끔하게 보이기 위해)
                hintText: 'YYYY-MM-DD', // 아무것도 없을 때 보여줄 안내 글자예요. (예: 2023-01-01)
                hintStyle: TextStyle(
                  // 안내 글자의 스타일을 정해요. (색깔을 살짝 흐리게)
                  color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.5),
                ),
              ),
              style: TextStyle(
                // 실제 날짜 글자의 스타일을 정해요. (앱의 기본 글자 색상 사용)
                color: Theme.of(context).textTheme.bodyMedium!.color,
              ),
              keyboardType: TextInputType.number, // 숫자 키보드를 보여줘요 (여기서는 직접 입력은 안돼요, 그냥 형식만 숫자).
              textAlign: TextAlign.center, // 글자를 가운데 정렬해요.
              onTap: showCalendar, // 이 부분을 누르면 showCalendar 함수를 실행해요. (달력이 나타나요)
            ),
          ),
          // 오른쪽 화살표 버튼이에요.
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios), // 오른쪽 화살표 모양 아이콘
            onPressed: onNextDay, // 버튼을 누르면 onNextDay 함수를 실행해요.
            color: Theme.of(context).iconTheme.color, // 앱의 기본 아이콘 색상을 사용해요.
          ),
        ],
      ),
    );
  }
}