import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Themes {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      onPrimary: Colors.white,
      secondary: Colors.orange, // For accent icons/elements
      onSecondary: Colors.white,
      surface: Colors.white, // For card backgrounds
      onSurface: Colors.black87, // For text/icons on surfaces
      background: Colors.white, // For general backgrounds
      onBackground: Colors.black87,
    ),
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white, // Redundant with colorScheme.surface, but kept for existing usage
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 4,
      shadowColor: Colors.black12,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(color: Colors.black87, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: Colors.black54),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    colorScheme: ColorScheme.dark(
      primary: Colors.blue[300]!,
      onPrimary: Colors.white,
      secondary: Colors.orange[300]!, // For accent icons/elements
      onSecondary: Colors.white,
      surface: Colors.grey[800]!, // For card backgrounds
      onSurface: Colors.white, // For text/icons on surfaces
      background: Colors.grey[900]!, // For general backgrounds
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[800],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    textTheme: const TextTheme(
      titleMedium: TextStyle(color: Colors.white, fontSize: 18),
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
    ),
    iconTheme: const IconThemeData(color: Colors.white70),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.grey[900],
      selectedItemColor: Colors.blue[300],
      unselectedItemColor: Colors.grey[400],
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

