// main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sweph/sweph.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'screens/home_screen.dart';
import 'screens/info_screen.dart';
import 'services/astro_state.dart';
import 'themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '오류가 발생하여 앱을 실행할 수 없습니다.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initSweph();
  }

  Future<void> _initSweph() async {
    try {
      await Sweph.init(epheAssets: [
        'assets/sweph/semo_18.se1',
        'assets/sweph/sepl_18.se1',
      ]);
    } catch (e) {
      throw Exception('Sweph 초기화 중 오류가 발생했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        } else if (snapshot.hasError) {
          return ErrorScreen(error: snapshot.error.toString());
        }

        return ChangeNotifierProvider(
          create: (context) {
            final astroState = AstroState();
            astroState.initialize();
            return astroState;
          },
          child: Consumer<AstroState>(
            builder: (context, astroState, child) {
              return ThemeProvider(
                initTheme: Theme.of(context).brightness == Brightness.dark
                    ? Themes.darkTheme
                    : Themes.lightTheme,
                builder: (context, myTheme) {
                  return MaterialApp(
                    title: 'Void of Course',
                    debugShowCheckedModeBanner: false,
                    theme: myTheme,
                    home: MainAppScreen(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final astroState = Provider.of<AstroState>(context);
    
    if (!astroState.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (astroState.lastError != null) {
      return Center(child: Text('Error: ${astroState.lastError}'));
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
            BottomNavigationBarItem(icon: Icon(Icons.info), label: '정보'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens() {
    return [
      HomeScreen(),
      const InfoScreen(),
    ];
  }
}