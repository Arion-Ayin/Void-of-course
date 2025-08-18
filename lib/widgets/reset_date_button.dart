
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.

// 날짜를 오늘로 되돌리는 동그란 버튼 위젯이에요.
class ResetDateButton extends StatelessWidget {
  // 버튼을 눌렀을 때 실행될 함수예요.
  final VoidCallback onPressed;

  // 이 위젯을 만들 때, 버튼을 누르면 실행될 함수를 꼭 받아야 해요.
  const ResetDateButton({super.key, required this.onPressed});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 화면의 가운데에 놓이도록 해요.
    return Align(
      alignment: Alignment.center, // 정렬을 가운데로 맞춰요.
      // 버튼의 크기를 정하기 위해 상자를 만들어요.
      child: SizedBox(
        width: 70, // 너비는 70
        height: 70, // 높이도 70
        // 우리가 흔히 쓰는 버튼이에요.
        child: ElevatedButton(
          onPressed: onPressed, // 버튼을 누르면 위에서 받은 함수를 실행해요.
          // 버튼의 스타일(모양, 색깔 등)을 정해요.
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero, // 버튼 안쪽의 여백을 없애요. 아이콘이 꽉 차게 보여요.
            // 버튼의 모양을 동그랗게 만들어요.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(35), // 너비와 높이의 절반 값으로 설정해서 완벽한 원을 만들어요.
            ),
          ),
          // 버튼 안에 들어갈 내용물이에요.
          child: const Icon(Icons.refresh, size: 30), // 새로고침 모양 아이콘을 넣고, 크기는 30으로 해요.
        ),
      ),
    );
  }
}
