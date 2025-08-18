
import 'package:flutter/material.dart'; // 플러터의 디자인 라이브러리를 가져와요.

// 앱의 저작권 정보를 보여주는 위젯이에요.
class CopyrightText extends StatelessWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요.
  const CopyrightText({super.key});

  @override
  // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요.
  Widget build(BuildContext context) {
    // 저작권 글자를 담을 상자를 만들어요.
    return Container(
      padding: const EdgeInsets.all(10), // 상자 안쪽에 모든 방향으로 10만큼 여백을 줘요.
      // 상자를 예쁘게 꾸며줘요.
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // 앱의 기본 카드 색상을 배경색으로 사용해요.
        borderRadius: BorderRadius.circular(16), // 모서리를 둥글게 깎아줘요.
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1), // 앱의 기본 그림자 색상을 아주 살짝 보이게 해요.
            blurRadius: 10, // 그림자를 부드럽게 퍼지게 해요.
            offset: const Offset(0, 5), // 그림자를 아래쪽으로 5만큼 이동시켜요.
          ),
        ],
      ),
      // 저작권 글자를 써요.
      child: Text(
        '© 2025 Studio_Saan. All rights reserved.', // 저작권 문구예요.
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), // 앱의 보통 글자 색상을 살짝 투명하게 사용해요.
          fontSize: 12, // 글자 크기는 12
          fontStyle: FontStyle.italic, // 글자를 기울여서 보여줘요.
        ),
        textAlign: TextAlign.center, // 글자를 가운데 정렬해요.
      ),
    );
  }
}
