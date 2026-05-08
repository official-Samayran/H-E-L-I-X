import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
export 'app_theme.dart';

enum ConfigLayoutType { tiles, switches }

class ThemeManager extends ChangeNotifier {
  AppThemeType _currentThemeType = AppThemeType.oled;
  bool _fpsSyncLock = false;
  double _uiScale = 1.0;
  double _hapticIntensity = 0.5;
  bool _showFpsCounter = false;
  
  // New Layout Settings
  ConfigLayoutType _configLayoutType = ConfigLayoutType.tiles;
  double _tileWidth = 105.0;
  double _tileHeight = 105.0;

  AppThemeType get currentThemeType => _currentThemeType;
  bool get fpsSyncLock => _fpsSyncLock;
  double get uiScale => _uiScale;
  double get hapticIntensity => _hapticIntensity;
  bool get showFpsCounter => _showFpsCounter;
  ConfigLayoutType get configLayoutType => _configLayoutType;
  double get tileWidth => _tileWidth;
  double get tileHeight => _tileHeight;
  
  AppThemeData get currentTheme => AppThemes.themes[_currentThemeType]!;

  ThemeManager() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currentThemeType = AppThemeType.values[prefs.getInt('theme_type') ?? AppThemeType.oled.index];
    _uiScale = prefs.getDouble('ui_scale') ?? 1.0;
    _hapticIntensity = prefs.getDouble('haptic_intensity') ?? 0.5;
    _showFpsCounter = prefs.getBool('show_fps_counter') ?? false;
    _configLayoutType = ConfigLayoutType.values[prefs.getInt('config_layout_type') ?? ConfigLayoutType.tiles.index];
    _tileWidth = prefs.getDouble('tile_width') ?? 105.0;
    _tileHeight = prefs.getDouble('tile_height') ?? 105.0;
    notifyListeners();
  }

  Future<void> changeTheme(AppThemeType themeType) async {
    if (_currentThemeType != themeType) {
      _currentThemeType = themeType;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_type', themeType.index);
      notifyListeners();
    }
  }

  void toggleFpsSyncLock(bool value) {
    if (_fpsSyncLock != value) {
      _fpsSyncLock = value;
      notifyListeners();
    }
  }

  void setUiScale(double scale) async {
    if (_uiScale != scale) {
      _uiScale = scale;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('ui_scale', scale);
      notifyListeners();
    }
  }

  void setHapticIntensity(double intensity) async {
    if (_hapticIntensity != intensity) {
      _hapticIntensity = intensity;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('haptic_intensity', intensity);
      notifyListeners();
    }
  }

  void toggleFpsCounter(bool value) async {
    if (_showFpsCounter != value) {
      _showFpsCounter = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_fps_counter', value);
      notifyListeners();
    }
  }

  void setConfigLayoutType(ConfigLayoutType type) async {
    if (_configLayoutType != type) {
      _configLayoutType = type;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('config_layout_type', type.index);
      notifyListeners();
    }
  }

  void setTileDimensions(double width, double height) async {
    _tileWidth = width;
    _tileHeight = height;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tile_width', width);
    await prefs.setDouble('tile_height', height);
    notifyListeners();
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
