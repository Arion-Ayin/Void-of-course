import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/astro_state.dart';
import '../themes.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  late AnimationController _iconRotationController;
  late Animation<double> _iconRotationAnimation;

  @override
  void initState() {
    super.initState();

    _iconRotationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_iconRotationController);
  }

  @override
  void dispose() {
    _iconRotationController.dispose();
    super.dispose();
  }

  void _onThemeChanged() {
    _iconRotationController.forward(from: 0.0);
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
  }) {
    return Builder(
      builder: (context) {
        return Container(
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
            title: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.8),
            Colors.indigo.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.brightness_3, color: Colors.white, size: 48),
          const SizedBox(height: 16),
          Text(
            'Lioluna',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Void of Course Calculator',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Info',
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
            elevation: Theme.of(context).appBarTheme.elevation,
            actions: [
              ThemeSwitcher(
                builder: (context) {
                  return Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: AnimatedBuilder(
                      animation: _iconRotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _iconRotationAnimation.value * 2 * 3.14159,
                          child: IconButton(
                            icon: Icon(
                              Theme.of(context).brightness == Brightness.dark
                                  ? Icons.wb_sunny
                                  : Icons.nightlight_round,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            onPressed: () {
                              _onThemeChanged();
                              final switcher = ThemeSwitcher.of(context);
                              final currentTheme = Theme.of(context);
                              if (currentTheme.brightness == Brightness.dark) {
                                switcher.changeTheme(theme: Themes.lightTheme);
                              } else {
                                switcher.changeTheme(theme: Themes.darkTheme);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            constraints: const BoxConstraints.expand(),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.background,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 800),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAppHeader(context),
                      const SizedBox(height: 30),
                      _buildInfoCard(
                        icon: Icons.star,
                        title: 'Who we are',
                        subtitle:
                            'Studio Saan Misson : \nFathoming the world \nwith the eyes of a lion \n사자의 눈으로 세상을 헤아린다.',
                        iconColor: Colors.amber,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        icon: Icons.update,
                        title: '버전 정보',
                        subtitle:
                            '현재 버전: 1.0.0\n\n'
                            '• 달 위상 계산\n'
                            '• 보이드 오브 코스\n'
                            '• 다크/라이트 모드\n'
                            '• 실시간 업데이트',
                        iconColor: Colors.green,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        icon: Icons.code,
                        title: '기술 스택',
                        subtitle:
                            '• Swiss Ephemeris\n'
                            '• Provider 패턴\n'
                            '• Material Design 3',
                        iconColor: Colors.purple,
                      ),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        icon: Icons.history,
                        title: '업데이트 로그',
                        subtitle:
                            'v1.0.0 (2025-08-14)\n'
                            '• 초기 릴리즈\n'
                            '• 달 위상 계산 기능\n'
                            '• 보이드 오브 코스 계산\n',
                        iconColor: Colors.orange,
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          '© 2025 Studio_Saan. All rights reserved.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }



}