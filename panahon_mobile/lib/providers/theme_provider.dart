import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF3B4A93),
    scaffoldBackgroundColor: const Color(0xFFF8F9FE),
    cardColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF3B4A93),
      foregroundColor: Color(0xFF0B0B0B),
      iconTheme: IconThemeData(color: Color(0xFF3B4A93)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF3B4A93),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3B4A93),
      secondary: Color(0xFF3B4A93),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0B0B0B),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF3B4A93)),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3B4A93),
    scaffoldBackgroundColor: const Color(0xFF0B0B0B),
    cardColor: const Color(0xFF0B0B0B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0B0B),
      foregroundColor: Color(0xFFFAFAFA),
      iconTheme: IconThemeData(color: Color(0xFF3B4A93)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0B0B0B),
      selectedItemColor: Color(0xFF3B4A93),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B4A93),
      secondary: Color(0xFF3B4A93),
      surface: Color(0xFF0B0B0B),
      onPrimary: Color(0xFFFAFAFA),
      onSurface: Color(0xFFFAFAFA),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF3B4A93)),
  );
}
