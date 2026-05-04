import 'package:flutter/material.dart';
import 'app_theme.dart';
export 'app_theme.dart';

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentThemeType = AppThemeType.helixPrime;
  bool _fpsSyncLock = false;
  double _uiScale = 1.0;
  int _fontWeightIndex = 3; // Default to w400

  AppThemeType get currentThemeType => _currentThemeType;
  bool get fpsSyncLock => _fpsSyncLock;
  double get uiScale => _uiScale;
  FontWeight get fontWeight => FontWeight.values[_fontWeightIndex];
  
  AppThemeData get currentTheme => AppThemes.themes[_currentThemeType]!;

  void changeTheme(AppThemeType themeType) {
    if (_currentThemeType != themeType) {
      _currentThemeType = themeType;
      notifyListeners();
    }
  }

  void toggleFpsSyncLock(bool value) {
    if (_fpsSyncLock != value) {
      _fpsSyncLock = value;
      notifyListeners();
    }
  }

  void setUiScale(double scale) {
    if (_uiScale != scale) {
      _uiScale = scale;
      notifyListeners();
    }
  }

  void setFontWeightIndex(int index) {
    if (_fontWeightIndex != index) {
      _fontWeightIndex = index;
      notifyListeners();
    }
  }

  // Helper getters for direct UI consumption
  Color get backgroundColor => currentTheme.backgroundColor;
  Color get auraColor => currentTheme.auraColor;
  Color get chatBackgroundColor => currentTheme.chatBackgroundColor;
  Color get textColor => currentTheme.textColor;
  Color get accentColor => currentTheme.accentColor;
  double get borderRadius => currentTheme.borderRadius;
  ThemeData get themeData => currentTheme.themeData;
}
