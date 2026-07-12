import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DaftarMasrofatyApp());
}

class AppColors {
  static const paper = Color(0xFFF1EAD9);
  static const paper2 = Color(0xFFE8DFC8);
  static const ink = Color(0xFF26313A);
  static const inkSoft = Color(0xFF5B6670);
  static const gold = Color(0xFFB8862B);
  static const teal = Color(0xFF1F6F5C);
  static const rust = Color(0xFFA83E2C);
  static const line = Color(0xFFD2C4A3);
  static const white = Color(0xFFFFFDF8);
}

class DaftarMasrofatyApp extends StatelessWidget {
  const DaftarMasrofatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دفتر مصروفاتي',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        fontFamily: 'Tajawal',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.ink,
          primary: AppColors.ink,
          secondary: AppColors.gold,
          surface: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: AppColors.line),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.line),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
