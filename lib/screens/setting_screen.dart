import 'package:flutter/material.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:provider/provider.dart';
import '../services/astro_state.dart';
import '../themes.dart';
import '../widgets/setting_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lioluna/services/locale_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// 설정 화면을 보여주는 위젯이에요.
class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final themeIcon = isDarkMode ? Icons.dark_mode : Icons.light_mode;
    final appLocalizations = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              appLocalizations.settings,
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                          duration = const Duration(seconds: 5);
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
            SettingCard(
              icon: themeIcon,
              title: appLocalizations.darkMode,
              iconColor: isDarkMode ? Colors.white : Colors.pink,
              trailing: ThemeSwitcher(
                builder: (context) {
                  final isDarkModeSwitch = Theme.of(context).brightness == Brightness.dark;
                  return Switch(
                    value: isDarkModeSwitch,
                    onChanged: (value) {
                      final theme = value ? Themes.darkTheme : Themes.lightTheme;
                      ThemeSwitcher.of(context).changeTheme(theme: theme);
                    },
                  );
                },
              ),
            ),
            SettingCard(
              icon: Icons.language,
              title: appLocalizations.languageSettings,
              iconColor: Colors.blue,
              trailing: DropdownButton<String>(
                value: localeProvider.locale?.languageCode,
                items: [
                  DropdownMenuItem(
                      value: 'ko',
                      child: Text(appLocalizations.korean)),
                  DropdownMenuItem(
                      value: 'en',
                      child: Text(appLocalizations.english)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  
                  Locale newLocale = Locale(value);
                  String message;

                  if (value == 'ko') {
                    message = '언어가 한국어로 변경되었습니다.';
                  } else {
                    message = 'Language changed to English.';
                  }

                  localeProvider.setLocale(newLocale);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            SettingCard(
              icon: Icons.feedback,
              title: appLocalizations.feedbackTitle,
              iconColor: Colors.orange,
              trailing: IconButton(
                icon: const Icon(Icons.mail, color: Colors.orange),
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