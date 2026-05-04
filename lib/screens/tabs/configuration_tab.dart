import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import '../../services/base_connection_provider.dart';
import '../../services/connection_service.dart';
import '../../theme/theme_manager.dart';

class ConfigurationTab extends StatefulWidget {
  const ConfigurationTab({super.key});

  @override
  State<ConfigurationTab> createState() => _ConfigurationTabState();
}

class _ConfigurationTabState extends State<ConfigurationTab> {
  late TextEditingController _ipController;
  late TextEditingController _nameController;
  late TextEditingController _macController;
  late TextEditingController _apiKeyController;
  
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;
  Timer? _inactivityTimer;

  // Toggle states
  bool _masterSwipe = true;
  bool _motionBlur = true;
  bool _neonEdge = false;
  bool _particleBg = false;
  bool _asciiMode = false;
  bool _fpsSyncLock = false;
  bool _voiceFlashlight = false;
  bool _weatherAura = true;
  bool _lowLatency = false;
  bool _secureScreen = false;
  double _hapticIntensity = 0.5;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BaseConnectionProvider>(context, listen: false);
    final connectionProvider = Provider.of<ConnectionService>(context, listen: false);
    _ipController = TextEditingController(text: provider.hostIP);
    _nameController = TextEditingController(text: provider.pcName);
    _macController = TextEditingController(text: provider.macAddress);
    _apiKeyController = TextEditingController(text: connectionProvider.geminiApiKey ?? '');
    
    _loadSecureScreenState();
    _authenticate();
  }

  Future<void> _loadSecureScreenState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _secureScreen = prefs.getBool('secure_screen_protocol') ?? false;
      _fpsSyncLock = prefs.getBool('fps_sync_lock') ?? false;
    });
    if (_fpsSyncLock && mounted) {
      Provider.of<ThemeManager>(context, listen: false).toggleFpsSyncLock(_fpsSyncLock);
    }
  }

  Future<void> _toggleSecureScreen(bool value) async {
    _resetInactivityTimer();
    setState(() => _secureScreen = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('secure_screen_protocol', value);
    
    const platform = MethodChannel('com.example.helix/secure');
    try {
      await platform.invokeMethod('setSecure', {'secure': value});
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _toggleFpsSyncLock(bool value) async {
    _resetInactivityTimer();
    setState(() => _fpsSyncLock = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fps_sync_lock', value);
    
    if (mounted) {
      Provider.of<ThemeManager>(context, listen: false).toggleFpsSyncLock(value);
    }
    
    const platform = MethodChannel('com.example.helix/secure');
    try {
      await platform.invokeMethod('setFrameRate', {'lock': value});
    } catch (e) {
      // Ignored
    }
  }

  Future<void> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isAuthenticating = false;
          });
        }
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock Helix Configuration',
        persistAcrossBackgrounding: true, 
        biometricOnly: true,
      );
      
      if (mounted) {
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isAuthenticating = false;
        });
      }
      
      if (didAuthenticate) {
        _resetInactivityTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isAuthenticating = false;
        });
      }
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ipController.dispose();
    _nameController.dispose();
    _macController.dispose();
    _apiKeyController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Widget _buildNeonToggle(String label, bool value, ValueChanged<bool> onChanged, ThemeManager theme) {
    return GestureDetector(
      onTap: () {
        _resetInactivityTimer();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.chatBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: theme.textColor, fontSize: 14)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: value ? theme.accentColor.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                border: Border.all(
                  color: value ? theme.accentColor : Colors.grey.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: value ? [BoxShadow(color: theme.accentColor.withOpacity(0.5), blurRadius: 8, spreadRadius: 1)] : [],
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: value ? theme.accentColor : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeManager theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.textColor.withOpacity(0.5),
          fontSize: 12,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    if (_isAuthenticating) {
      return Center(child: CircularProgressIndicator(color: theme.accentColor));
    }
    
    if (!_isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: theme.accentColor),
            const SizedBox(height: 16),
            Text('ACCESS DENIED', style: TextStyle(color: theme.textColor, fontSize: 20, letterSpacing: 4)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentColor),
              onPressed: _authenticate,
              child: const Text('AUTHENTICATE'),
            )
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {},
      color: theme.accentColor,
      backgroundColor: theme.chatBackgroundColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'C O N T R O L  C E N T E R',
            style: TextStyle(
              color: theme.textColor,
              fontSize: 18,
              letterSpacing: 4,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildSectionHeader('Visuals', theme),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: DropdownButtonFormField<AppThemeType>(
              value: theme.currentThemeType,
              dropdownColor: theme.chatBackgroundColor,
              style: TextStyle(color: theme.textColor),
              onChanged: (AppThemeType? newTheme) {
                _resetInactivityTimer();
                if (newTheme != null) {
                  Provider.of<ThemeManager>(context, listen: false).changeTheme(newTheme);
                }
              },
              decoration: InputDecoration(
                labelText: 'Engine Theme',
                labelStyle: TextStyle(color: theme.textColor.withOpacity(0.6)),
                filled: true,
                fillColor: theme.chatBackgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: AppThemeType.values.map((type) {
                final themeData = AppThemes.themes[type];
                if (themeData == null) return null;
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: themeData.accentColor)),
                      const SizedBox(width: 8),
                      Text(themeData.name),
                    ],
                  ),
                );
              }).whereType<DropdownMenuItem<AppThemeType>>().toList(),
            ),
          ),
          _buildNeonToggle('Master Swipe Mode', _masterSwipe, (v) => setState(() => _masterSwipe = v), theme),
          _buildNeonToggle('Motion Blur', _motionBlur, (v) => setState(() => _motionBlur = v), theme),
          _buildNeonToggle('Neon Edge Lighting', _neonEdge, (v) => setState(() => _neonEdge = v), theme),
          _buildNeonToggle('Particle Background', _particleBg, (v) => setState(() => _particleBg = v), theme),

          _buildSectionHeader('Hardware', theme),
          _buildNeonToggle('Voice Flashlight (Lumos/Nox)', _voiceFlashlight, (v) => setState(() => _voiceFlashlight = v), theme),
          _buildNeonToggle('Weather-Aura Sync', _weatherAura, (v) => setState(() => _weatherAura = v), theme),

          _buildSectionHeader('System', theme),
          _buildNeonToggle('Secure Screen Protocol', _secureScreen, _toggleSecureScreen, theme),
          _buildNeonToggle('Low-Latency Mode', _lowLatency, (v) => setState(() => _lowLatency = v), theme),
          _buildNeonToggle('144 FPS Sync Lock', _fpsSyncLock, _toggleFpsSyncLock, theme),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UI Scale: ${theme.uiScale.toStringAsFixed(2)}x', style: TextStyle(color: theme.textColor, fontSize: 14)),
                Slider(
                  value: theme.uiScale,
                  min: 0.8,
                  max: 1.2,
                  divisions: 4,
                  activeColor: theme.accentColor,
                  inactiveColor: theme.accentColor.withOpacity(0.2),
                  onChanged: (val) {
                    _resetInactivityTimer();
                    Provider.of<ThemeManager>(context, listen: false).setUiScale(val);
                  },
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Font Weight: ${theme.fontWeight.toString()}', style: TextStyle(color: theme.textColor, fontSize: 14)),
                Slider(
                  value: theme.fontWeight.index.toDouble(),
                  min: 0,
                  max: 8,
                  divisions: 8,
                  activeColor: theme.accentColor,
                  inactiveColor: theme.accentColor.withOpacity(0.2),
                  onChanged: (val) {
                    _resetInactivityTimer();
                    Provider.of<ThemeManager>(context, listen: false).setFontWeightIndex(val.toInt());
                  },
                ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Haptic Intensity', style: TextStyle(color: theme.textColor, fontSize: 14)),
          ),
          Slider(
            value: _hapticIntensity,
            onChanged: (v) {
              _resetInactivityTimer();
              setState(() => _hapticIntensity = v);
            },
            activeColor: theme.accentColor,
            inactiveColor: theme.textColor.withOpacity(0.1),
          ),
          
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.chatBackgroundColor,
              foregroundColor: theme.textColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              // Cache Cleaner logic mock
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cache Cleared'), backgroundColor: theme.accentColor));
            },
            child: const Text('CLEAN CACHE', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
          
          _buildSectionHeader('Legacy Network Config', theme),
          _buildField('Host IP Address', _ipController, theme),
          const SizedBox(height: 16),
          _buildField('PC Name', _nameController, theme),
          const SizedBox(height: 16),
          _buildField('MAC Address (WoL)', _macController, theme),
          const SizedBox(height: 32),

          _buildSectionHeader('API Integration', theme),
          _buildModelSelector(context, theme),
          const SizedBox(height: 16),
          _buildField('Gemini API Key', _apiKeyController, theme, obscureText: true),
          const SizedBox(height: 32),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.accentColor,
              foregroundColor: theme.backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              Provider.of<BaseConnectionProvider>(context, listen: false)
                  .saveConfigs(_ipController.text.trim(), _nameController.text.trim(), _macController.text.trim());
              Provider.of<ConnectionService>(context, listen: false)
                  .setGeminiApiKey(_apiKeyController.text.trim());
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Configuration Saved', style: TextStyle(color: theme.backgroundColor)), backgroundColor: theme.accentColor),
              );
            },
            child: const Text('SAVE CONFIGURATION', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeManager theme, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: theme.textColor),
      onChanged: (_) => _resetInactivityTimer(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withOpacity(0.6)),
        filled: true,
        fillColor: theme.chatBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, ThemeManager theme) {
    final connectionService = Provider.of<ConnectionService>(context);
    return DropdownButtonFormField<String>(
      value: connectionService.selectedModel,
      dropdownColor: theme.chatBackgroundColor,
      style: TextStyle(color: theme.textColor),
      onChanged: (String? value) {
        _resetInactivityTimer();
        if (value != null) {
          connectionService.setModel(value);
        }
      },
      decoration: InputDecoration(
        labelText: 'AI Engine',
        labelStyle: TextStyle(color: theme.textColor.withOpacity(0.6)),
        filled: true,
        fillColor: theme.chatBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Gemini', child: Text('Gemini Cloud')),
        DropdownMenuItem(value: 'Ollama', child: Text('Local Ollama (11434)')),
      ],
    );
  }
}
