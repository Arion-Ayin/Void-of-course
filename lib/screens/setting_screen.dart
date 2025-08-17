import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../services/astro_state.dart';
import '../themes.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({Key? key}) : super(key: key);

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget trailing,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark; // This line should be here
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
              '설정',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSettingCard(
              context: context,
              icon: isDarkMode ? Icons.dark_mode : Icons.sunny, // This should be conditional
              title: '다크 모드',
              iconColor: isDarkMode ? Colors.white : Colors.yellow, // This should be conditional
              trailing: ThemeSwitcher(
                builder: (context) {
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  return Switch(
                    value: isDarkMode,
                    onChanged: (value) {
                      final theme = value ? Themes.darkTheme : Themes.lightTheme;
                      ThemeSwitcher.of(context).changeTheme(theme: theme);
                    },
                  );
                },
              ),
            ),
            _buildSettingCard(
              context: context,
              icon: Icons.language,
              title: '언어 설정',
              iconColor: Colors.blue,
              trailing: DropdownButton<String>(
                value: '한국어',
                items: const [
                  DropdownMenuItem(value: '한국어', child: Text('한국어')),
                  DropdownMenuItem(value: 'English', child: Text('English')),
                ],
                onChanged: (value) {
                  // Handle language change
                },
              ),
            ),
            _buildSettingCard(
              context: context,
              icon: Icons.info_outline,
              title: '앱 정보',
              iconColor: Colors.green,
              trailing: IconButton(
                icon: Icon(Icons.info, color: Colors.green),
                onPressed: () {
                  // Navigate to app info screen
                },
              ),
            ),

            _buildSettingCard(
              context: context,
              icon: Icons.feedback,
              title: '피드백',
              iconColor: Colors.orange,
              trailing: IconButton(
                icon: Icon(Icons.mail, color: Colors.orange),
                onPressed: () {
                  // Open feedback form
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}