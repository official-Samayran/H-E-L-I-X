import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
export 'app_theme.dart';

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentThemeType = AppThemeType.oled;
  bool _fpsSyncLock = false;
  double _uiScale = 1.0;
  double _hapticIntensity = 0.5;
  bool _showFpsCounter = false;

  AppThemeType get currentThemeType => _currentThemeType;
  bool get fpsSyncLock => _fpsSyncLock;
  double get uiScale => _uiScale;
  double get hapticIntensity => _hapticIntensity;
  bool get showFpsCounter => _showFpsCounter;
  
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

  void setHapticIntensity(double intensity) {
    if (_hapticIntensity != intensity) {
      _hapticIntensity = intensity;
      notifyListeners();
    }
  }

  void toggleFpsCounter(bool value) {
    if (_showFpsCounter != value) {
      _showFpsCounter = value;
      notifyListeners();
    }
  }

  void triggerHaptic() {
    if (_hapticIntensity == 0.0) return;
    
    if (_hapticIntensity >= 0.8) {
      HapticFeedback.heavyImpact();
    } else if (_hapticIntensity >= 0.4) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
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
