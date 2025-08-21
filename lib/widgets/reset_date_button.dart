// 플러터의 디자인 라이브러리를 가져와요. 화면에 보이는 것들을 만들 때 필요해요.
import 'package:flutter/material.dart';

// 날짜를 오늘로 되돌리는 동그란 버튼 위젯이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class ResetDateButton extends StatelessWidget {
  // 버튼을 눌렀을 때 실행될 함수예요. onPressed는 버튼이 눌렸을 때 어떤 일을 할지 정하는 거예요.
  final VoidCallback onPressed;

  // 이 위젯을 만들 때, 버튼을 누르면 실행될 함수를 꼭 받아야 해요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const ResetDateButton({super.key, required this.onPressed});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 화면의 가운데에 놓이도록 해요. Align은 위젯을 정렬할 때 사용해요.
    return Align(
      alignment: Alignment.center, // 정렬을 가운데로 맞춰요.
      // 버튼의 크기를 정하기 위해 상자를 만들어요. SizedBox는 위젯의 크기를 정할 때 사용해요.
      child: SizedBox(
        width: 70, // 너비는 70
        height: 70, // 높이도 70
        // 우리가 흔히 쓰는 버튼이에요. ElevatedButton은 그림자가 있는 버튼이에요.
        child: ElevatedButton(
          onPressed: onPressed, // 버튼을 누르면 위에서 받은 onPressed 함수를 실행해요.
          // 버튼의 스타일(모양, 색깔 등)을 정해요. styleFrom은 버튼의 모양을 꾸미는 도구예요.
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // 버튼 안쪽의 여백을 없애요. 아이콘이 꽉 차게 보여요.
            // 버튼의 모양을 동그랗게 만들어요. shape는 위젯의 모양을 정해요.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35), // 모서리를 35만큼 둥글게 만들어서 완벽한 원을 만들어요. (너비/높이의 절반)
            ),
          ),
          // 버튼 안에 들어갈 내용물이에요. child는 버튼 안에 들어갈 내용이에요.
          child: const Icon(Icons.refresh, size: 35), // 새로고침 모양 아이콘을 넣고, 크기는 35로 해요.
        ),
      ),
    );
  }
}