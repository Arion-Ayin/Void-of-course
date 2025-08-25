import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Themes {
  //light theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light, // 이 테마는 밝은 모드예요.
    primarySwatch: Colors.blue, // 앱의 주요 색상으로 파란색 계열을 사용해요. (여러 파란색 농도를 자동으로 만들어줘요)
    colorScheme: const ColorScheme.light( // 밝은 테마에 맞는 색상들을 자세히 정해요.
      primary: Colors.blue, // 주요 색상 (버튼, 아이콘 등)
      onPrimary: Colors.white, // 주요 색상 위에 올라가는 글자나 아이콘 색상
      secondary: Colors.orange, // 강조 색상 (특별한 아이콘이나 요소)
      onSecondary: Colors.white, // 강조 색상 위에 올라가는 글자나 아이콘 색상
      surface: Colors.white, // 카드나 배경처럼 평평한 면의 색상
      onSurface: Colors.black87, // 평평한 면 위에 올라가는 글자나 아이콘 색상
      background: Colors.white, // 일반적인 화면 배경색
      onBackground: Colors.black87, // 배경 위에 올라가는 글자나 아이콘 색상
    ),
    scaffoldBackgroundColor: Colors.white, // Scaffold(앱의 기본 뼈대)의 배경색을 하얀색으로 해요.
    cardColor: Colors.white, // 카드 위젯의 배경색을 하얀색으로 해요. (colorScheme.surface와 중복될 수 있지만, 기존 사용을 위해 유지해요)
    appBarTheme: const AppBarTheme( // 앱 바(화면 상단 제목 부분)의 디자인을 정해요.
      backgroundColor: Colors.white, // 앱 바의 배경색은 하얀색
      foregroundColor: Colors.black87, // 앱 바의 글자나 아이콘 색상은 거의 검은색
      elevation: 4, // 앱 바 아래에 그림자를 4만큼 만들어요.
      shadowColor: Colors.black12, // 그림자 색상은 살짝 투명한 검은색
      systemOverlayStyle: SystemUiOverlayStyle.dark, // 시스템 UI(상태표시줄)의 글자나 아이콘을 어둡게 보여줘요.
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold), // 제목 글자 스타일
    ),
    textTheme: const TextTheme( // 앱의 글자 스타일을 정해요.
      titleMedium: TextStyle(color: Colors.black87, fontSize: 18), // 중간 크기 제목 글자색은 거의 검은색, 크기는 18
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14), // 일반 본문 글자색은 회색, 크기는 14
    ),
    iconTheme: const IconThemeData(color: Colors.black54), // 앱의 모든 아이콘 색상을 회색으로 해요.
    bottomNavigationBarTheme: const BottomNavigationBarThemeData( // 하단 내비게이션 바의 디자인을 정해요.
      backgroundColor: Colors.white, // 배경색은 하얀색
      selectedItemColor: Colors.blue, // 선택된 항목의 색상은 파란색
      unselectedItemColor: Colors.grey, // 선택되지 않은 항목의 색상은 회색
      type: BottomNavigationBarType.fixed, // 항목들의 크기를 고정해요.
      elevation: 8, // 그림자를 8만큼 만들어요.
    ),
  );

  //dark theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark, // 이 테마는 어두운 모드예요.
    primarySwatch: Colors.blue, // 앱의 주요 색상으로 파란색 계열을 사용해요.
    colorScheme: ColorScheme.dark( // 어두운 테마에 맞는 색상들을 자세히 정해요.
      primary: Colors.blue[300]!, // 주요 색상 (밝은 파란색)
      onPrimary: Colors.white, // 주요 색상 위에 올라가는 글자나 아이콘 색상
      secondary: Colors.orange[300]!, // 강조 색상 (밝은 주황색)
      onSecondary: Colors.white, // 강조 색상 위에 올라가는 글자나 아이콘 색상
      surface: Colors.grey[800]!, // 카드나 배경처럼 평평한 면의 색상 (어두운 회색)
      onSurface: Colors.white, // 평평한 면 위에 올라가는 글자나 아이콘 색상
      background: Colors.grey[900]!, // 일반적인 화면 배경색 (아주 어두운 회색)
      onBackground: Colors.white, // 배경 위에 올라가는 글자나 아이콘 색상
    ),
    scaffoldBackgroundColor: Colors.grey[900], // Scaffold(앱의 기본 뼈대)의 배경색을 아주 어두운 회색으로 해요.
    cardColor: Colors.grey[800], // 카드 위젯의 배경색을 어두운 회색으로 해요.
    appBarTheme: AppBarTheme( // 앱 바(화면 상단 제목 부분)의 디자인을 정해요.
      backgroundColor: Colors.grey[900], // 앱 바의 배경색은 아주 어두운 회색
      foregroundColor: Colors.white, // 앱 바의 글자나 아이콘 색상은 하얀색
      elevation: 0, // 앱 바 아래에 그림자를 없애요.
      shadowColor: Colors.transparent, // 그림자가 없다는 뜻
      systemOverlayStyle: SystemUiOverlayStyle.light, // 시스템 UI(상태표시줄)의 글자나 아이콘을 밝게 보여줘요.
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), // 제목 글자 스타일
    ),
    textTheme: const TextTheme( // 앱의 글자 스타일을 정해요.
      titleMedium: TextStyle(color: Colors.white, fontSize: 18), // 중간 크기 제목 글자색은 하얀색, 크기는 18
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14), // 일반 본문 글자색은 살짝 투명한 하얀색, 크기는 14
    ),
    iconTheme: const IconThemeData(color: Colors.white70), // 앱의 모든 아이콘 색상을 살짝 투명한 하얀색으로 해요.
    bottomNavigationBarTheme: BottomNavigationBarThemeData( // 하단 내비게이션 바의 디자인을 정해요.
      backgroundColor: Colors.grey[900], // 배경색은 아주 어두운 회색
      selectedItemColor: Colors.blue[300], // 선택된 항목의 색상은 밝은 파란색
      unselectedItemColor: Colors.grey[400], // 선택되지 않은 항목의 색상은 밝은 회색
      type: BottomNavigationBarType.fixed, // 항목들의 크기를 고정해요.
      elevation: 8, // 그림자를 8만큼 만들어요.
    ),
  );
}