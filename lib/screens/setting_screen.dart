import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:provider/provider.dart';
import '../services/astro_state.dart';
import '../themes.dart';
import '../widgets/setting_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lioluna/services/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// 설정 화면을 보여주는 위젯이에요. StatelessWidget은 한 번 만들어지면 잘 변하지 않는 위젯이라는 뜻이에요.
class SettingScreen extends StatelessWidget {
  // const는 이 위젯이 변하지 않는다는 뜻이에요. super.key는 위젯을 구분하는 이름표 같은 거예요.
  const SettingScreen({super.key});

    // 이 위젯이 화면에 어떻게 보일지 정하는 부분이에요. Widget은 화면에 보이는 모든 것을 뜻해요.
  Widget build(BuildContext context) {
    // 현재 테마가 다크 모드인지 확인해요. Theme.of(context).brightness는 현재 테마의 밝기를 알려줘요.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 다크 모드일 때는 달 아이콘, 아닐 때는 해 아이콘을 보여줘요.
    final themeIcon = isDarkMode ? Icons.dark_mode : Icons.light_mode;
    final appLocalizations = AppLocalizations.of(context)!;

    // 화면의 전체적인 구조를 짜요. Scaffold는 기본적인 앱 디자인을 제공하는 위젯이에요.
    return Scaffold(
      // 화면 상단의 앱 바(제목 바)예요. AppBar는 앱의 맨 위에 있는 막대기예요.
      appBar: AppBar(
        // 제목 부분에 아이콘과 글자를 가로로 나란히 놓아요. Row는 위젯들을 가로로 나란히 놓을 때 사용해요.
        title: Row(
          children: [
            // 설정 아이콘이에요. Icon은 그림 아이콘을 보여줘요.
            Icon(
              Icons.settings, // 설정 아이콘 모양이에요.
              color: Theme.of(context).colorScheme.primary, // 앱 테마의 기본 색깔을 사용해요. (예: 파란색)
              size: 24, // 아이콘 크기는 24
            ),
            const SizedBox(width: 8), // 아이콘과 글자 사이에 작은 공간을 만들어요. SizedBox는 빈 공간을 만들어요.
            // '설정'이라는 제목을 써요. Text는 글자를 보여줘요.
            Text(
              appLocalizations.settings,
              style: TextStyle(
                // 다크 모드일 때는 하얀색, 아닐 때는 검은색 계열 글자색을 사용해요.
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // 앱 바의 배경색을 테마에 맞게 설정해요.
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor, // 앱 바의 글자/아이콘 색을 테마에 맞게 설정해요.
        elevation: Theme.of(context).appBarTheme.elevation, // 앱 바의 그림자 높이를 테마에 맞게 설정해요. (높을수록 그림자가 진해져요)
      ),
      // 화면의 주요 내용이 들어가는 부분이에요. body는 Scaffold의 몸통 부분이에요.
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 모든 방향으로 16만큼 여백을 줘요. Padding은 위젯 주변에 여백을 줘요.
        // 설정 항목들을 세로로 차곡차곡 쌓아요. Column은 위젯들을 세로로 쌓을 때 사용해요.
        child: Column(
          children: [
            SettingCard(
              icon: Icons.notifications_active_outlined,
              title: appLocalizations.voidAlarmTitle,
              iconColor: Colors.deepPurpleAccent,
              trailing: Consumer<AstroState>(
                builder: (context, astroState, child) {
                  return Switch(
                    value: astroState.voidAlarmEnabled,
                    onChanged: (value) async {
                      final status = await astroState.toggleVoidAlarm(value);
                      if (!context.mounted) return;

                      String message = '';
                      Duration duration = const Duration(seconds: 2);

                      switch (status) {
                        case AlarmPermissionStatus.granted:
                          message = value 
                              ? appLocalizations.voidAlarmEnabledMessage
                              : appLocalizations.voidAlarmDisabledMessage;
                          break;
                        case AlarmPermissionStatus.notificationDenied:
                          message = appLocalizations.voidAlarmDisabledMessage;
                          break;
                        case AlarmPermissionStatus.exactAlarmDenied:
                          message = appLocalizations.voidAlarmExactAlarmDeniedMessage;
                          duration = const Duration(seconds: 5); // Give user more time to read
                          break;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: duration,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 1. 다크 모드 설정 카드
            SettingCard(
              icon: themeIcon, // 위에서 정한 테마 아이콘(달 또는 해)을 보여줘요.
              title: appLocalizations.darkMode,
              iconColor: isDarkMode ? Colors.white : Colors.pink, // 다크 모드일 땐 하얀색, 아닐 땐 핑크색 아이콘
              // 카드 오른쪽에 스위치를 넣어요. trailing은 목록의 맨 뒤에 오는 위젯이에요.
              trailing: ThemeSwitcher(
                builder: (context) {
                  // 현재 테마가 다크 모드인지 다시 확인해요. (스위치 상태를 정확히 맞추기 위해)
                  final isDarkModeSwitch = Theme.of(context).brightness == Brightness.dark;
                  // 스위치 위젯을 만들어요.
                  return Switch(
                    value: isDarkModeSwitch, // 스위치의 켜짐/꺼짐 상태를 정해요. (true면 켜짐, false면 꺼짐)
                    // 스위치를 누를 때마다 실행될 함수예요. value는 스위치가 켜졌는지(true) 꺼졌는지(false) 알려줘요.
                    onChanged: (value) {
                      // 스위치가 켜지면(value=true) 다크 테마, 꺼지면 라이트 테마를 선택해요.
                      final theme = value ? Themes.darkTheme : Themes.lightTheme;
                      // 앱의 테마를 선택한 테마로 바꿔줘요. ThemeSwitcher.of(context).changeTheme는 테마를 바꾸는 특별한 기능이에요.
                      ThemeSwitcher.of(context).changeTheme(theme: theme);
                    },
                  );
                },
              ),
            ),

            SettingCard(
              icon: Icons.language, // 언어 아이콘
              title: appLocalizations.languageSettings, // 제목은 '언어 설정'
              iconColor: Colors.blue, // 아이콘 색깔은 파란색
              // 카드 오른쪽에 드롭다운 메뉴를 넣어요. DropdownButton은 여러 선택지 중 하나를 고를 때 사용해요.
              trailing: Consumer<LocaleProvider>(
                builder: (context, localeProvider, child) {
                  return DropdownButton<String>(
                    value: localeProvider.locale?.languageCode == 'ko'
                        ? appLocalizations.korean
                        : appLocalizations.english,
                    // 선택할 수 있는 항목들이에요. DropdownMenuItem은 드롭다운 메뉴의 각 항목이에요.
                    items: [
                      DropdownMenuItem(
                          value: appLocalizations.korean,
                          child: Text(appLocalizations.korean)), // '한국어' 항목
                      DropdownMenuItem(
                          value: appLocalizations.english,
                          child: Text(appLocalizations.english)), // 'English' 항목
                    ],
                    onChanged: (value) {
                      Locale newLocale;
                      String message;
                      if (value == appLocalizations.korean) {
                        newLocale = const Locale('ko');
                        message = '언어가 한국어로 변경되었습니다.';
                      } else if (value == appLocalizations.english) {
                        newLocale = const Locale('en');
                        message = 'Language changed to English.';
                      } else {
                        return; // Should not happen
                      }
                      localeProvider.setLocale(newLocale);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            SettingCard(
              icon: Icons.feedback, // 피드백 아이콘
              title: appLocalizations.feedbackTitle,
              iconColor: Colors.orange, // 아이콘 색깔은 주황색
              // 카드 오른쪽에 아이콘 버튼을 넣어요.
              trailing: IconButton(
                icon: const Icon(Icons.mail, color: Colors.orange), // 메일 아이콘 버튼
                onPressed: () async {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'Arion.Ayin@gmail.com',
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'Feedback for Void-of-course App',
                    }),
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${appLocalizations.mailAppError}\n${appLocalizations.contactEmail}'),
                      )
                    );
                  }
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}


String? encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((MapEntry<String, String> e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}