import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'screens/home_screen.dart';
import 'screens/info_screen.dart';
import 'screens/setting_screen.dart';
import 'services/astro_state.dart';
import 'themes.dart';
import 'services/notification_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lioluna/services/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart'; // url_launcher 추가

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AstroState()..initialize()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      initTheme: Theme.of(context).brightness == Brightness.dark
          ? Themes.darkTheme
          : Themes.lightTheme,
      builder: (context, myTheme) {
        final localeProvider = Provider.of<LocaleProvider>(context);
        return MaterialApp(
          title: 'Void of Course',
          debugShowCheckedModeBanner: false,
          theme: myTheme,
          home: const MainAppScreen(),
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        );
      },
    );
  }
}

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialLocale = Provider.of<LocaleProvider>(context, listen: false).locale;
      if (initialLocale != null) {
        Provider.of<AstroState>(context, listen: false)
            .updateLocale(initialLocale.languageCode);
      }
      // 업데이트 확인
      _checkForUpdates();
    });
  }

  // 업데이트 확인 로직 (예시)
  Future<bool> _hasUpdate() async {
    try {
      print('Checking for updates...');
      return true; // 테스트용, 실제 로직으로 교체
    } catch (e) {
      print('Update check failed: $e');
      return false;
    }
  }

  // Google Play Store로 이동
  Future<void> _launchStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.example.voidofcourse'; // 실제 앱 ID로 교체
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Play Store를 열 수 없습니다.')),
      );
    }
  }

  // 업데이트 알림 팝업
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('업데이트 하시겠습니까?'),
          content: const Text('새로운 버전의 앱이 있습니다. 최신 기능과 개선 사항을 위해 지금 업데이트하세요!'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchStore();
              },
              child: const Text('업데이트'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('나중에'),
            ),
          ],
        );
      },
    );
  }

  // 업데이트 확인 및 팝업 호출
  Future<void> _checkForUpdates() async {
    bool hasUpdate = await _hasUpdate();
    if (hasUpdate && mounted) {
      _showUpdateDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    final astroState = Provider.of<AstroState>(context);

    if (!astroState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (astroState.lastError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '오류가 발생하여 앱을 실행할 수 없습니다.\n\n${astroState.lastError}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.blue[300]
              : Colors.blue[600],
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[400]
              : Colors.grey[600],
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
            BottomNavigationBarItem(icon: Icon(Icons.info), label: '정보'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      const HomeScreen(),
      const SettingScreen(),
      const InfoScreen(),
    ];
  }
}