import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType {
  helixPrime,
  glassmorphism,
  neuralDark,
  averoLight,
  stealth,
  crimson,
  oled,
}

class AppThemeData {
  final AppThemeType type;
  final String name;
  final Color backgroundColor;
  final Color auraColor;
  final Color chatBackgroundColor;
  final Color textColor;
  final Color accentColor;
  final ThemeData themeData;

  const AppThemeData({
    required this.type,
    required this.name,
    required this.backgroundColor,
    required this.auraColor,
    required this.chatBackgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.themeData,
  });
}

class AppThemes {
  static final Map<AppThemeType, AppThemeData> themes = {
    AppThemeType.helixPrime: AppThemeData(
      type: AppThemeType.helixPrime,
      name: 'Helix Prime',
      backgroundColor: Colors.black,
      auraColor: Colors.cyanAccent,
      chatBackgroundColor: const Color(0xFF1A1A1A),
      textColor: Colors.white,
      accentColor: Colors.cyanAccent,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.cyanAccent,
          secondary: Colors.cyanAccent,
          surface: const Color(0xFF1A1A1A),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
    ),
    AppThemeType.glassmorphism: AppThemeData(
      type: AppThemeType.glassmorphism,
      name: 'Glassmorphism',
      backgroundColor: const Color(0xFF0D1B2A),
      auraColor: const Color(0xFF415A77),
      chatBackgroundColor: const Color(0x40FFFFFF),
      textColor: Colors.white,
      accentColor: const Color(0xFF778DA9),
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF778DA9),
          secondary: const Color(0xFF415A77),
          surface: const Color(0x40FFFFFF),
        ),
        cardTheme: CardThemeData(
          color: const Color(0x40FFFFFF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ),
    AppThemeType.neuralDark: AppThemeData(
      type: AppThemeType.neuralDark,
      name: 'Neural Dark',
      backgroundColor: const Color(0xFF121212),
      auraColor: Colors.greenAccent,
      chatBackgroundColor: const Color(0xFF1E1E1E),
      textColor: const Color(0xFFE0E0E0),
      accentColor: Colors.greenAccent,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme).apply(bodyColor: const Color(0xFFE0E0E0), displayColor: const Color(0xFFE0E0E0)),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.greenAccent,
          secondary: Colors.greenAccent,
          surface: const Color(0xFF1E1E1E),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    AppThemeType.averoLight: AppThemeData(
      type: AppThemeType.averoLight,
      name: 'Avero Light',
      backgroundColor: Colors.white,
      auraColor: const Color(0xFF82B1FF),
      chatBackgroundColor: const Color(0xFFF5F5F5),
      textColor: Colors.black87,
      accentColor: const Color(0xFF448AFF),
      themeData: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme).apply(bodyColor: Colors.black87, displayColor: Colors.black87),
        colorScheme: const ColorScheme.light().copyWith(
          primary: const Color(0xFF448AFF),
          secondary: const Color(0xFF82B1FF),
          surface: const Color(0xFFF5F5F5),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    AppThemeType.stealth: AppThemeData(
      type: AppThemeType.stealth,
      name: 'Stealth',
      backgroundColor: const Color(0xFF1C1C1C),
      auraColor: const Color(0xFF9E9E9E),
      chatBackgroundColor: const Color(0xFF2C2C2C),
      textColor: const Color(0xFFE0E0E0),
      accentColor: Colors.grey,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1C1C1C),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(bodyColor: const Color(0xFFE0E0E0), displayColor: const Color(0xFFE0E0E0)),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.grey,
          secondary: const Color(0xFF9E9E9E),
          surface: const Color(0xFF2C2C2C),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
      ),
    ),
    AppThemeType.crimson: AppThemeData(
      type: AppThemeType.crimson,
      name: 'Crimson',
      backgroundColor: const Color(0xFF212121),
      auraColor: const Color(0xFFD50000),
      chatBackgroundColor: const Color(0xFF303030),
      textColor: Colors.white,
      accentColor: Colors.redAccent,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF212121),
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.redAccent,
          secondary: const Color(0xFFD50000),
          surface: const Color(0xFF303030),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF303030),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    AppThemeType.oled: AppThemeData(
      type: AppThemeType.oled,
      name: 'OLED',
      backgroundColor: Colors.black,
      auraColor: Colors.white,
      chatBackgroundColor: Colors.black,
      textColor: Colors.white,
      accentColor: Colors.white,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Colors.black,
        ),
        cardTheme: CardThemeData(
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.white24)),
        ),
      ),
    ),
  };
}
