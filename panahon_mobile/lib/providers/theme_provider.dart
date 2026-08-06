import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;
  bool get isDark => _isDark;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // Off White: #F5F2ED -> 0xFFF5F2ED
  // Crimson Red: #8B0D1A -> 0xFF8B0D1A
  // Black: #0B0B0B -> 0xFF0B0B0B

  ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF8B0D1A),
    scaffoldBackgroundColor: const Color(0xFFF5F2ED),
    cardColor: const Color(0xFFF5F2ED),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5F2ED),
      foregroundColor: Color(0xFF0B0B0B),
      iconTheme: IconThemeData(color: Color(0xFF8B0D1A)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFF5F2ED),
      selectedItemColor: Color(0xFF8B0D1A),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF8B0D1A),
      secondary: const Color(0xFF8B0D1A),
      background: const Color(0xFFF5F2ED),
      surface: const Color(0xFFF5F2ED),
      onPrimary: const Color(0xFFF5F2ED),
      onBackground: const Color(0xFF0B0B0B),
      onSurface: const Color(0xFF0B0B0B),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF8B0D1A)),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF8B0D1A),
    scaffoldBackgroundColor: const Color(0xFF0B0B0B),
    cardColor: const Color(0xFF0B0B0B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0B0B0B),
      foregroundColor: Color(0xFFF5F2ED),
      iconTheme: IconThemeData(color: Color(0xFF8B0D1A)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0B0B0B),
      selectedItemColor: Color(0xFF8B0D1A),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF8B0D1A),
      secondary: const Color(0xFF8B0D1A),
      background: const Color(0xFF0B0B0B),
      surface: const Color(0xFF0B0B0B),
      onPrimary: const Color(0xFFF5F2ED),
      onBackground: const Color(0xFFF5F2ED),
      onSurface: const Color(0xFFF5F2ED),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF8B0D1A)),
  );
}
