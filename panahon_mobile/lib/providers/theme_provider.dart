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
    primaryColor: const Color(0xFF60519B),
    scaffoldBackgroundColor: const Color(0xFFF8F9FE),
    cardColor: const Color(0xFFFFFFFF),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF60519B),
      foregroundColor: Color(0xFFFFFFFF),
      iconTheme: IconThemeData(color: Color(0xFFFFFFFF)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF60519B),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF60519B),
      secondary: Color(0xFFBFC0D1),
      surface: Color(0xFFFFFFFF),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF0B0B0B),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF60519B)),
  );

  ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF60519B),
    scaffoldBackgroundColor: const Color(0xFF1E202C),
    cardColor: const Color(0xFF31323E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E202C),
      foregroundColor: Color(0xFFFAFAFA),
      iconTheme: IconThemeData(color: Color(0xFF60519B)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E202C),
      selectedItemColor: Color(0xFF60519B),
      unselectedItemColor: Colors.grey,
    ),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF60519B),
      secondary: Color(0xFFBFC0D1),
      surface: Color(0xFF31323E),
      onPrimary: Color(0xFFFAFAFA),
      onSurface: Color(0xFFFAFAFA),
    ),
    iconTheme: const IconThemeData(color: Color(0xFF60519B)),
  );
}
