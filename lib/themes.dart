import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Themes {
  // 우주적 색상 팔레트 - 달과 별의 신비로움을 담다

  // Light Theme Colors
  static const Color _lightBackground = Color(0xFFF8F6F0); // 따뜻한 아이보리
  static const Color _lightSurface = Color(0xFFFFFDF8); // 부드러운 크림색
  static const Color _lightCard = Color(0xFFFFFFFF); // 순백
  static const Color _lightPrimary = Color(0xFF2C3E50); // 깊은 미드나잇 블루
  static const Color _lightSecondary = Color(0xFFD4AF37); // 골드
  static const Color _lightText = Color(0xFF1A1A2E); // 깊은 네이비
  static const Color _lightTextSecondary = Color(0xFF4A4A5A); // 부드러운 그레이

  // Dark Theme Colors
  static const Color _darkBackground = Color(0xFF0F0F1A); // 깊은 우주 블랙
  static const Color _darkSurface = Color(0xFF1A1A2E); // 미드나잇 네이비
  static const Color _darkCard = Color(0xFF16213E); // 깊은 인디고
  static const Color _darkPrimary = Color(0xFFE8D5B7); // 달빛 크림
  static const Color _darkSecondary = Color(0xFFD4AF37); // 골드
  static const Color _darkText = Color(0xFFF0EDE5); // 별빛 화이트
  static const Color _darkTextSecondary = Color(0xFFB8B5AD); // 부드러운 실버

  //light theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blueGrey,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: Colors.white,
      secondary: _lightSecondary,
      onSecondary: Colors.white,
      surface: _lightSurface,
      onSurface: _lightText,
      background: _lightBackground,
      onBackground: _lightText,
    ),
    scaffoldBackgroundColor: _lightBackground,
    cardColor: _lightCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: _lightPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      titleTextStyle: TextStyle(
        color: _lightPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: _lightText, fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: _lightText, fontSize: 18, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: _lightText, fontSize: 16),
      bodyMedium: TextStyle(color: _lightTextSecondary, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: _lightPrimary),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightCard,
      selectedItemColor: _lightPrimary,
      unselectedItemColor: _lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  //dark theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blueGrey,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimary,
      onPrimary: _darkBackground,
      secondary: _darkSecondary,
      onSecondary: _darkBackground,
      surface: _darkSurface,
      onSurface: _darkText,
      background: _darkBackground,
      onBackground: _darkText,
    ),
    scaffoldBackgroundColor: _darkBackground,
    cardColor: _darkCard,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkPrimary,
      elevation: 0,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      titleTextStyle: TextStyle(
        color: _darkPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(color: _darkText, fontSize: 20, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: _darkText, fontSize: 18, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(color: _darkText, fontSize: 16),
      bodyMedium: TextStyle(color: _darkTextSecondary, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: _darkPrimary),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurface,
      selectedItemColor: _darkSecondary,
      unselectedItemColor: _darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
