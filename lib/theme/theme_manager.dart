import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentThemeType = AppThemeType.helixPrime;

  AppThemeType get currentThemeType => _currentThemeType;
  
  AppThemeData get currentTheme => AppThemes.themes[_currentThemeType]!;

  void changeTheme(AppThemeType themeType) {
    if (_currentThemeType != themeType) {
      _currentThemeType = themeType;
      notifyListeners();
    }
  }

  // Helper getters for direct UI consumption
  Color get backgroundColor => currentTheme.backgroundColor;
  Color get auraColor => currentTheme.auraColor;
  Color get chatBackgroundColor => currentTheme.chatBackgroundColor;
  Color get textColor => currentTheme.textColor;
  Color get accentColor => currentTheme.accentColor;
  ThemeData get themeData => currentTheme.themeData;
}
