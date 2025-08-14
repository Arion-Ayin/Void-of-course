// SettingScreen.dart

// Flutter의 기본 재료들을 가져옵니다. 화면을 만드는 데 꼭 필요해요.
import 'package:flutter/material.dart';
// 앱에 데이터를 저장하고 불러오는 도구(Shared Preferences)를 가져옵니다.
import 'package:shared_preferences/shared_preferences.dart';
// 앱의 전체적인 색깔과 디자인을 정해둔 파일을 가져옵니다.
import 'package:lioluna/themes.dart';

// SettingScreen은 '설정' 화면입니다.
// 이 화면은 데이터가 바뀌지 않기 때문에 'StatelessWidget'을 사용합니다.
class SettingScreen extends StatelessWidget {
  // 테마(화면의 색깔)가 바뀌었을 때, 다른 화면에 알려주는 함수를 준비합니다.
  final Function(ThemeMode) onThemeChanged; // 테마 변경 콜백

  // SettingScreen 위젯을 만듭니다. onThemeChanged 함수를 꼭 받아야 합니다.
  const SettingScreen({super.key, required this.onThemeChanged});

  // 화면에 무엇을 보여줄지 결정하는 중요한 함수입니다.
  @override
  Widget build(BuildContext context) {
    // Scaffold는 앱 화면의 기본 틀(바탕)입니다.
    return Scaffold(
      // AppBar는 화면의 맨 위에 있는 막대입니다. '설정'이라는 제목을 붙여줍니다.
      appBar: AppBar(title: const Text('설정')),
      // body는 화면의 주요 내용을 담는 부분입니다.
      body: Center(
        // 화면의 중앙에 아이콘 버튼을 하나 놓습니다.
        child: IconButton(
          // 아이콘의 모양을 정합니다.
          icon: Icon(
            // 현재 화면이 어두운 모드인지 확인합니다.
            Theme.of(context).brightness == Brightness.dark
                // 어두운 모드일 때 해 아이콘(밝은 아이콘)을 보여줍니다.
                ? Icons.wb_sunny
                // 밝은 모드일 때 달 아이콘(어두운 아이콘)을 보여줍니다.
                : Icons.nightlight_round,
          ),
          // 버튼을 눌렀을 때 실행되는 함수입니다.
          onPressed: () async {
            // 앱에 데이터를 저장하는 도구(SharedPreferences)를 가져옵니다.
            final prefs = await SharedPreferences.getInstance();
            // 현재 화면이 어두운 모드인지 다시 확인하여 'isDark' 변수에 저장합니다.
            final isDark = Theme.of(context).brightness == Brightness.dark;
            // 현재가 어두운 모드라면 밝은 모드로, 밝은 모드라면 어두운 모드로 바꿀 준비를 합니다.
            final newThemeMode = isDark ? ThemeMode.light : ThemeMode.dark;

            // 바뀐 테마 정보를 'themeMode'라는 이름으로 앱에 저장합니다.
            await prefs.setString('themeMode', newThemeMode.toString());
            // 바뀐 테마 정보를 다른 화면들에게 알려줍니다.
            onThemeChanged(newThemeMode);
          },
          // 아이콘의 색깔을 현재 테마에 맞춰 정합니다.
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}