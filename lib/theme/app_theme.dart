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
  ascii,
  cyberpunk,
  minecraft,
  valorant,
  gtaV,
  racing,
  neumorphic,
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
  final double borderRadius;

  const AppThemeData({
    required this.type,
    required this.name,
    required this.backgroundColor,
    required this.auraColor,
    required this.chatBackgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.themeData,
    this.borderRadius = 16.0,
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
        textTheme: GoogleFonts.tekoTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.white,
          secondary: Colors.white,
          surface: Colors.black,
        ),
        dividerColor: Colors.white38,
        cardTheme: CardThemeData(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), 
            side: const BorderSide(color: Colors.white38, width: 1.5),
          ),
        ),
      ),
    ),
    AppThemeType.ascii: AppThemeData(
      type: AppThemeType.ascii,
      name: 'ASCII Mode',
      backgroundColor: Colors.black,
      auraColor: Colors.greenAccent,
      chatBackgroundColor: Colors.black,
      textColor: Colors.greenAccent,
      accentColor: Colors.greenAccent,
      borderRadius: 0.0,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.jetBrainsMonoTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.greenAccent, displayColor: Colors.greenAccent),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.greenAccent,
          secondary: Colors.greenAccent,
          surface: Colors.black,
        ),
        cardTheme: CardThemeData(
          color: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0), side: const BorderSide(color: Colors.greenAccent)),
        ),
      ),
    ),
    AppThemeType.cyberpunk: AppThemeData(
      type: AppThemeType.cyberpunk,
      name: 'Cyberpunk',
      backgroundColor: Colors.black,
      auraColor: const Color(0xFFFDEE00),
      chatBackgroundColor: const Color(0xFF111111),
      textColor: const Color(0xFFFDEE00),
      accentColor: const Color(0xFFFDEE00),
      borderRadius: 8.0,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme).apply(bodyColor: const Color(0xFFFDEE00), displayColor: const Color(0xFFFDEE00)),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFFDEE00),
          secondary: const Color(0xFFFDEE00),
          surface: const Color(0xFF111111),
        ),
      ),
    ),
    AppThemeType.minecraft: AppThemeData(
      type: AppThemeType.minecraft,
      name: 'Minecraft',
      backgroundColor: const Color(0xFF3B2F2F),
      auraColor: const Color(0xFF55FF55),
      chatBackgroundColor: const Color(0xFF5C4033),
      textColor: const Color(0xFFFFFFFF),
      accentColor: const Color(0xFF55FF55),
      borderRadius: 0.0,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF3B2F2F),
        textTheme: GoogleFonts.vt323TextTheme(ThemeData.dark().textTheme).apply(bodyColor: const Color(0xFFFFFFFF), displayColor: const Color(0xFFFFFFFF)),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF55FF55),
          secondary: const Color(0xFF55FF55),
          surface: const Color(0xFF5C4033),
        ),
      ),
    ),
    AppThemeType.valorant: AppThemeData(
      type: AppThemeType.valorant,
      name: 'Valorant',
      backgroundColor: const Color(0xFF111111),
      auraColor: const Color(0xFF00ADAA),
      chatBackgroundColor: const Color(0xFF1F2326),
      textColor: Colors.white,
      accentColor: const Color(0xFF00ADAA),
      borderRadius: 0.0,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF111111),
        textTheme: GoogleFonts.tekoTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF00ADAA),
          secondary: const Color(0xFF00ADAA),
          surface: const Color(0xFF1F2326),
        ),
      ),
    ),
    AppThemeType.gtaV: AppThemeData(
      type: AppThemeType.gtaV,
      name: 'GTA V',
      backgroundColor: Colors.black,
      auraColor: const Color(0xFF4CBB17),
      chatBackgroundColor: const Color(0xFF1A1A1A),
      textColor: Colors.white,
      accentColor: const Color(0xFF4CBB17),
      borderRadius: 4.0,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.bebasNeueTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFF4CBB17),
          secondary: const Color(0xFF4CBB17),
          surface: const Color(0xFF1A1A1A),
        ),
      ),
    ),
    AppThemeType.racing: AppThemeData(
      type: AppThemeType.racing,
      name: 'Racing',
      backgroundColor: const Color(0xFF2A2A2A),
      auraColor: const Color(0xFFD3D3D3),
      chatBackgroundColor: const Color(0xFF333333),
      textColor: const Color(0xFFFFFFFF),
      accentColor: const Color(0xFFC0C0C0),
      borderRadius: 12.0,
      themeData: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF2A2A2A),
        textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: const Color(0xFFC0C0C0),
          secondary: const Color(0xFFD3D3D3),
          surface: const Color(0xFF333333),
        ),
      ),
    ),
    AppThemeType.neumorphic: AppThemeData(
      type: AppThemeType.neumorphic,
      name: 'Neumorphic',
      backgroundColor: const Color(0xFFE0E5EC),
      auraColor: const Color(0xFFA3B1C6),
      chatBackgroundColor: const Color(0xFFE0E5EC),
      textColor: const Color(0xFF4A5568),
      accentColor: const Color(0xFF3182CE),
      borderRadius: 20.0,
      themeData: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFE0E5EC),
        textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme).apply(bodyColor: const Color(0xFF4A5568), displayColor: const Color(0xFF4A5568)),
        colorScheme: const ColorScheme.light().copyWith(
          primary: const Color(0xFF3182CE),
          secondary: const Color(0xFFA3B1C6),
          surface: const Color(0xFFE0E5EC),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFE0E5EC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
      ),
    ),
  };
}

