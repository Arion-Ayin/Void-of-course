// FlushbarHelper.dart

// Flutter의 기본 재료들을 가져옵니다. 화면을 만드는 데 꼭 필요해요.
import 'package:flutter/material.dart';
// 'another_flushbar'라는 알림 메시지를 쉽게 만드는 도구를 가져옵니다.
import 'package:another_flushbar/flushbar.dart';

// FlushbarHelper는 알림 메시지를 보여주는 것을 도와주는 '도우미' 역할을 하는 클래스입니다.
class FlushbarHelper {
  // 이 함수는 에러(오류) 메시지를 화면 아래에 보여주는 역할을 합니다.
  // 'static'은 이 함수를 FlushbarHelper라는 클래스 이름으로 바로 사용할 수 있게 해줍니다.
  static void showError(BuildContext context, String message) {
    // Flushbar라는 알림 메시지 위젯을 만듭니다.
    Flushbar(
      // 'message'는 알림 창에 보여줄 글자입니다.
      message: message,
      // 'backgroundColor'는 알림 창의 배경색입니다. 빨간색으로 정해서 오류임을 알려줍니다.
      backgroundColor: Colors.redAccent,
      // 'duration'은 알림 창이 얼마나 오래 화면에 있을지 정하는 시간입니다. 3초로 정했습니다.
      duration: const Duration(seconds: 3),
      // 'flushbarPosition'은 알림 창이 화면의 어느 위치에 나타날지 정합니다. 아래쪽에 표시됩니다.
      flushbarPosition: FlushbarPosition.BOTTOM,
      // 'margin'은 알림 창과 화면 가장자리 사이에 여백을 줍니다.
      margin: const EdgeInsets.all(8),
      // 'borderRadius'는 알림 창의 모서리를 둥글게 만들어줍니다.
      borderRadius: BorderRadius.circular(8),
    ).show(context); // 만들어진 알림 창을 화면에 실제로 보여줍니다.
  }

  // 이 함수는 성공 메시지를 화면 아래에 보여주는 역할을 합니다.
  static void showSuccess(BuildContext context, String message) {
    // Flushbar라는 알림 메시지 위젯을 만듭니다.
    Flushbar(
      // 'message'는 알림 창에 보여줄 글자입니다.
      message: message,
      // 'backgroundColor'는 알림 창의 배경색입니다. 초록색으로 정해서 성공임을 알려줍니다.
      backgroundColor: Colors.green,
      // 'duration'은 알림 창이 얼마나 오래 화면에 있을지 정하는 시간입니다. 3초로 정했습니다.
      duration: const Duration(seconds: 3),
      // 'flushbarPosition'은 알림 창이 화면의 어느 위치에 나타날지 정합니다. 아래쪽에 표시됩니다.
      flushbarPosition: FlushbarPosition.BOTTOM,
      // 'margin'은 알림 창과 화면 가장자리 사이에 여백을 줍니다.
      margin: const EdgeInsets.all(8),
      // 'borderRadius'는 알림 창의 모서리를 둥글게 만들어줍니다.
      borderRadius: BorderRadius.circular(8),
    ).show(context); // 만들어진 알림 창을 화면에 실제로 보여줍니다.
  }
}