// 이 파일은 앱의 설정 화면을 만드는 코드를 담고 있어요.
// 화면에 여러 가지 설정을 담은 카드들을 보여줘요.

import 'package:flutter/material.dart'; // Flutter 앱의 기본 위젯들을 가져와요.
import 'package:animated_theme_switcher/animated_theme_switcher.dart'; // 테마를 바꿀 때 멋진 애니메이션을 보여주는 라이브러리예요.
import 'package:provider/provider.dart'; // 앱의 상태(데이터)를 여러 위젯이 쉽게 공유할 수 있게 해주는 도구예요.
import '../services/astro_state.dart'; // 천문학 관련 상태를 관리하는 파일을 가져와요. (예: 보이드 알람 켜고 끄기)
import '../themes.dart'; // 앱의 밝은 테마와 어두운 테마 정보를 가져와요.
import '../widgets/setting_card.dart'; // 설정 화면에 보이는 카드 모양 위젯을 가져와요.
import 'package:void_of_course/l10n/app_localizations.dart'; // 앱의 언어(한국어, 영어 등)를 쉽게 바꾸기 위한 파일을 가져와요.
import 'package:void_of_course/services/locale_provider.dart'; // 앱의 현재 언어 설정을 관리하는 파일을 가져와요.
import 'package:url_launcher/url_launcher.dart'; // 웹사이트나 이메일 앱을 열어주는 라이브러리예요.
import '../widgets/reusable_native_ad_widget.dart';
import '../services/ad_service.dart';

// 설정 화면을 보여주는 위젯이에요.
class SettingScreen extends StatelessWidget {
  // 이 위젯은 변하지 않는 내용을 보여줘서 StatelessWidget으로 만들었어요.
  const SettingScreen({super.key}); // 위젯을 만들 때 필요한 기본 정보예요.

  Future<void> _showUrlConfirmationDialog(
    BuildContext context, {

    required String url,

    required String serviceNameKo,

    required String serviceNameEn,
  }) async {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    final isKorean = localeProvider.locale?.languageCode == 'ko';

    final String title =
        isKorean ? '$serviceNameKo로 이동' : 'Go to $serviceNameEn';

    final String contentText = isKorean ? '$serviceNameKo(으)로 이동하시겠습니까?' : '';

    final String yesButton = isKorean ? '예' : 'Yes';

    final String noButton = isKorean ? '아니오' : 'No';

    return showDialog<void>(
      context: context,

      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(contentText),

              const SizedBox(height: 16),

              const ReusableNativeAdWidget(),
            ],
          ),

          actions: <Widget>[
            TextButton(
              child: Text(noButton),

              onPressed: () {
                Navigator.of(context).pop();
              },
            ),

            TextButton(
              child: Text(yesButton),

              onPressed: () async {
                Navigator.of(context).pop();

                final Uri uri = Uri.parse(url);

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // URL을 열 수 없을 때 화면 아래에 알림 메시지를 띄워줘요.

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch $url')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 이 함수는 화면에 무엇을 그릴지 정해줘요.
  @override
  Widget build(BuildContext context) {
    // 현재 앱이 어두운 모드인지 아닌지 확인해요.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 어두운 모드면 달 아이콘을, 아니면 해 아이콘을 보여줄 거예요.
    final themeIcon = isDarkMode ? Icons.dark_mode : Icons.light_mode;
    // 현재 설정된 언어에 맞는 글씨들을 가져와요.
    final appLocalizations = AppLocalizations.of(context)!;
    // 언어 설정을 바꾸는 데 필요한 정보를 가져와요.
    final localeProvider = Provider.of<LocaleProvider>(context);

    // 화면의 기본 틀을 만들어요.
    return Scaffold(
      // 화면 맨 위에 보이는 막대(바)를 만들어요.
      appBar: AppBar(
        // 막대 왼쪽에 아이콘과 제목을 나란히 놓을 거예요.
        title: Row(
          children: [
            // 설정 아이콘을 보여줘요.
            Icon(
              Icons.settings,
              color:
                  Theme.of(
                    context,
                  ).colorScheme.primary, // 앱의 주요 색깔로 아이콘 색을 정해요.
              size: 24, // 아이콘 크기를 24로 정해요.
            ),
            const SizedBox(width: 8), // 아이콘과 글씨 사이에 작은 공간을 만들어요.
            Text(
              appLocalizations.settings, // '설정'이라는 글씨를 현재 언어에 맞게 보여줘요.
            ),
          ],
        ),
        // 막대의 배경색, 글씨색, 그림자 효과를 앱의 테마에 맞게 정해요.
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      // 화면의 나머지 부분을 채워요.
      body: SafeArea(
        child: SingleChildScrollView(
          // 화면을 스크롤 가능하게 만들어요.
          child: Padding(
            padding: const EdgeInsets.all(16.0), // 화면 가장자리로부터 16만큼 떨어뜨려요.
            child: Column(
              // 카드들을 위에서 아래로 차례대로 쌓을 거예요.
              children: [
              // 첫 번째 설정 카드: 보이드 알람 켜기/끄기
              SettingCard(
                icon: Icons.notifications_active_outlined, // 알림 아이콘을 보여줘요.
                title: appLocalizations.voidAlarmTitle, // '보이드 알람'이라는 제목을 보여줘요.
                iconColor: Colors.deepPurpleAccent, // 아이콘 색깔을 보라색으로 정해요.
                trailing: Consumer<AstroState>(
                  // 'AstroState'라는 상태 변화를 지켜볼 거예요.
                  builder: (context, astroState, child) {
                    // 스위치 버튼을 만들어요.
                    return Switch(
                      value:
                          astroState
                              .voidAlarmEnabled, // 스위치의 현재 상태(켜짐/꺼짐)를 AstroState에서 가져와요.
                      onChanged: (value) async {
                        // 스위치를 누르면 이 코드가 실행돼요.
                        // 보이드 알람을 켜거나 끄는 함수를 불러와요.
                        final status = await astroState.toggleVoidAlarm(value);
                        // 만약 위젯이 화면에서 사라졌다면 아무것도 하지 않아요.
                        if (!context.mounted) return;

                        String message = ''; // 화면 아래에 잠깐 나타날 메시지를 담을 변수예요.
                        Duration duration = const Duration(
                          seconds: 2,
                        ); // 메시지가 2초 동안 보이게 할 거예요.

                        // 알람 허용 상태에 따라 다른 메시지를 보여줘요.
                        switch (status) {
                          case AlarmPermissionStatus.granted: // 알람이 허용되었다면
                            message =
                                value // 스위치가 켜졌는지 꺼졌는지에 따라 메시지를 다르게 보여줘요.
                                    ? appLocalizations
                                        .voidAlarmEnabledMessage // 켜졌을 때 메시지
                                    : appLocalizations
                                        .voidAlarmDisabledMessage; // 꺼졌을 때 메시지
                            break;
                          case AlarmPermissionStatus
                              .notificationDenied: // 알림 권한이 거부되었다면
                            message =
                                appLocalizations
                                    .voidAlarmDisabledMessage; // 알람을 끌 수밖에 없다는 메시지를 보여줘요.
                            break;
                          case AlarmPermissionStatus
                              .exactAlarmDenied: // 정확한 알람 권한이 거부되었다면 (안드로이드 특정 기능)
                            message =
                                appLocalizations
                                    .voidAlarmExactAlarmDeniedMessage; // 권한이 필요하다는 메시지를 보여줘요.
                            duration = const Duration(seconds: 2);
                            break;
                        }

                        // 화면 아래에 알림 메시지를 잠깐 띄워줘요.
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message), // 위에서 정한 메시지를 보여줘요.
                            duration: const Duration(seconds: 2), // 2초 동안 보여줘요.
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // 두 번째 설정 카드: 다크 모드 켜기/끄기
              SettingCard(
                icon: themeIcon, // 위에서 정한 달 또는 해 아이콘을 보여줘요.
                title: appLocalizations.darkMode, // '다크 모드'라는 제목을 보여줘요.
                iconColor:
                    isDarkMode
                        ? Colors.white
                        : Colors.pink, // 다크 모드일 땐 흰색, 아닐 땐 분홍색으로 아이콘 색을 정해요.
                trailing: ThemeSwitcher(
                  // 테마 변경을 위한 스위치를 만들어요.
                  builder: (context) {
                    // 현재 테마가 다크 모드인지 다시 확인해요.
                    final isDarkModeSwitch =
                        Theme.of(context).brightness == Brightness.dark;
                    return Switch(
                      value: isDarkModeSwitch, // 스위치의 현재 상태를 현재 테마에 맞게 정해요.
                      onChanged: (value) {
                        // 스위치를 누르면 이 코드가 실행돼요.
                        // 스위치 상태에 따라 밝은 테마 또는 어두운 테마를 정해요.
                        final theme =
                            value ? Themes.darkTheme : Themes.lightTheme;
                        // 앱의 테마를 새로운 테마로 바꿔줘요.
                        ThemeSwitcher.of(context).changeTheme(theme: theme);
                      },
                    );
                  },
                ),
              ),
              // 세 번째 설정 카드: 언어 설정
              SettingCard(
                icon: Icons.language, // 언어 아이콘을 보여줘요.
                title:
                    appLocalizations.languageSettings, // '언어 설정'이라는 제목을 보여줘요.
                iconColor: Colors.blue, // 아이콘 색깔을 파란색으로 정해요.
                trailing: DropdownButton<String>(
                  // 드롭다운 메뉴를 만들어요.
                  value:
                      localeProvider
                          .locale
                          ?.languageCode, // 현재 언어 코드를 드롭다운 메뉴의 선택 값으로 정해요.
                  items: [
                    // 영어 옵션을 만들어요.
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(appLocalizations.english),
                    ), // '영어'라는 글씨를 현재 언어에 맞게 보여줘요.
                    // 한국어 옵션을 만들어요.
                    DropdownMenuItem(
                      value: 'ko',
                      child: Text(appLocalizations.korean),
                    ), // '한국어'라는 글씨를 현재 언어에 맞게 보여줘요.
                  ],
                  onChanged: (value) {
                    // 드롭다운 메뉴에서 다른 것을 고르면 이 코드가 실행돼요.
                    if (value == null) return; // 선택된 값이 없다면 아무것도 하지 않아요.

                    final newLocale = Locale(value); // 선택된 값으로 새로운 언어 정보를 만들어요.
                    String message; // 화면 아래에 잠깐 나타날 메시지를 담을 변수예요.

                    // 선택된 언어에 따라 다른 메시지를 정해요.
                    if (value == 'ko') {
                      message = '언어가 한국어로 변경되었습니다.';
                    } else {
                      message = 'Language changed to English.';
                    }

                    // 1. 먼저 UI의 언어부터 즉시 변경합니다.
                    localeProvider.setLocale(newLocale);

                    // 2. 잠시 후 (UI 변경이 완료될 시간을 준 후) 알람 업데이트를 수행합니다.
                    // 이렇게 하면 UI 버벅임이 사라집니다.
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (context.mounted) {
                        Provider.of<AstroState>(
                          context,
                          listen: false,
                        ).updateLocale(newLocale.languageCode);
                      }
                    });

                    // 화면 아래에 언어 변경 알림 메시지를 잠깐 띄워줘요.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(message), // 위에서 정한 메시지를 보여줘요.
                        duration: const Duration(seconds: 1), // 2초 동안 보여줘요.
                      ),
                    );
                  },
                ),
              ),

              // ▼▼▼ 여기가 수정된 네 번째 설정 카드입니다 ▼▼▼
              SettingCard(
                icon: Icons.coffee_outlined, // 네이버 카페를 상징하는 커피 아이콘
                title: appLocalizations.community, // '커뮤니티' 제목
                iconColor: const Color(0xFF03C75A), // 네이버 녹색
                trailing: IconButton(
                  // 오른쪽 끝에 버튼을 추가
                  icon: const Icon(
                    Icons.arrow_forward_ios, // 오른쪽 화살표 아이콘
                    size: 30,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // 버튼을 누르면 기존에 만드신 확인 대화상자를 띄웁니다.
                    _showUrlConfirmationDialog(
                      context,
                      url: 'https://arion-ayin.github.io/',
                      serviceNameKo: '블로그',
                      serviceNameEn: 'Blog',
                    );
                  },
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
