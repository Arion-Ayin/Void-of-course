// SettingScreen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lioluna/themes.dart';
import '../services/astro_state.dart'; // AstroState 파일을 가져옵니다.

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // AstroState의 변화를 감지하고 데이터를 가져옵니다.
    final astroState = Provider.of<AstroState>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: Center(
        child: IconButton(
          icon: Icon(
            // ⭐ AstroState의 isDarkMode 상태에 따라 아이콘을 바꿉니다.
            astroState.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
          ),
          onPressed: () {
            // ⭐ AstroState의 테마 토글 메서드를 호출합니다.
            // SharedPreferences 로직은 AstroState 클래스 내부에 있을 것입니다.
            astroState.toggleTheme();
          },
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}