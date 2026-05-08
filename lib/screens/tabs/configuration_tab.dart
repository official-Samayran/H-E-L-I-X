import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:ui';
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
  late TextEditingController _helixPersonalizationController;
  late TextEditingController _conodePersonalizationController;
  String _selectedHelixPreset = 'Custom';
  String _selectedConodePreset = 'Custom';
  
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;
  Timer? _inactivityTimer;

  // Toggle states
  bool _secureScreen = false;
  bool _fpsSyncLock = false;
  
  // New Functional Toggles
  bool _markdownParsing = true;
  bool _autoScroll = true;
  bool _typingCursor = true;
  
  bool _hardwareAccel = true;
  bool _bgPolling = true;
  
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BaseConnectionProvider>(context, listen: false);
    final connectionProvider = Provider.of<ConnectionService>(context, listen: false);
    _ipController = TextEditingController(text: provider.hostIP);
    _nameController = TextEditingController(text: provider.pcName);
    _macController = TextEditingController(text: provider.macAddress);
    _apiKeyController = TextEditingController(text: connectionProvider.geminiApiKey ?? '');
    _helixPersonalizationController = TextEditingController(text: connectionProvider.helixSystemPrompt);
    _conodePersonalizationController = TextEditingController(text: connectionProvider.conodeSystemPrompt);
    
    _loadSecureScreenState();
    _authenticate();
  }

  Future<void> _loadSecureScreenState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _secureScreen = prefs.getBool('secure_screen_protocol') ?? false;
      _fpsSyncLock = prefs.getBool('fps_sync_lock') ?? false;
    });
    if (mounted) {
      final theme = Provider.of<ThemeManager>(context, listen: false);
      if (_fpsSyncLock) theme.toggleFpsSyncLock(_fpsSyncLock);
      setState(() {
        _markdownParsing = prefs.getBool('markdown_parsing') ?? true;
        _autoScroll = prefs.getBool('auto_scroll') ?? true;
        _typingCursor = prefs.getBool('typing_cursor') ?? true;
        _hardwareAccel = prefs.getBool('hardware_accel') ?? true;
        _bgPolling = prefs.getBool('bg_polling') ?? true;
      });
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
    _pageController.dispose();
    _ipController.dispose();
    _nameController.dispose();
    _macController.dispose();
    _apiKeyController.dispose();
    _helixPersonalizationController.dispose();
    _conodePersonalizationController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleGeneric(String key, bool value, Function(bool) stateSetter) async {
    _resetInactivityTimer();
    stateSetter(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Widget _buildControlCenterTile(String label, IconData icon, bool value, ValueChanged<bool> onChanged, ThemeManager theme) {
    return GestureDetector(
      onTap: () {
        _resetInactivityTimer();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: theme.tileWidth,
        height: theme.tileHeight,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? theme.accentColor : theme.chatBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? theme.accentColor : theme.textColor.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: value ? [BoxShadow(color: theme.accentColor.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 1)] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: (theme.tileWidth + theme.tileHeight) / 8,
              color: value ? theme.backgroundColor : theme.textColor.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: value ? theme.backgroundColor : theme.textColor.withValues(alpha: 0.9),
                fontSize: (theme.tileWidth + theme.tileHeight) / 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(String label, IconData icon, bool value, ValueChanged<bool> onChanged, ThemeManager theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: theme.accentColor),
      title: Text(label, style: TextStyle(color: theme.textColor, fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: (v) {
          _resetInactivityTimer();
          onChanged(v);
        },
        activeColor: theme.accentColor,
      ),
    );
  }



  Widget _buildSectionHeader(String title, ThemeManager theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: theme.textColor.withValues(alpha: 0.5),
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

    return Row(
      children: [
        Expanded(
          child: PageView(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
            },
            children: [
              _buildGlassCard(theme, 'Aesthetics & UI', _buildAestheticsContent(theme)),
              _buildGlassCard(theme, 'System & Hardware', _buildHardwareContent(theme)),
              _buildGlassCard(theme, 'Network & API', _buildNetworkContent(theme)),
              _buildGlassCard(theme, 'AI Personalisation', _buildPersonalizationContent(theme)),
            ],
          ),
        ),
        Container(
          width: 48,
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIconIndicator(0, Icons.palette_outlined, theme),
              const SizedBox(height: 16),
              _buildIconIndicator(1, Icons.memory_outlined, theme),
              const SizedBox(height: 16),
              _buildIconIndicator(2, Icons.cloud_outlined, theme),
              const SizedBox(height: 16),
              _buildIconIndicator(3, Icons.person_outline, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconIndicator(int index, IconData icon, ThemeManager theme) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.all(isActive ? 10 : 6),
        decoration: BoxDecoration(
          color: isActive ? theme.accentColor.withValues(alpha: 0.2) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: isActive ? 24 : 16,
          color: isActive ? theme.accentColor : theme.textColor.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildGlassCard(ThemeManager theme, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Center(
        child: Container(
          height: 600,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.currentThemeType == AppThemeType.oled
                ? Colors.black
                : theme.chatBackgroundColor.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: theme.currentThemeType == AppThemeType.oled 
                    ? theme.textColor.withValues(alpha: 0.3) 
                    : theme.textColor.withValues(alpha: 0.05), 
                width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: TextStyle(color: theme.textColor, fontSize: 16, letterSpacing: 4, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: children,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAestheticsContent(ThemeManager theme) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: DropdownButtonFormField<AppThemeType>(
          initialValue: theme.currentThemeType,
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
            labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.6)),
            filled: true,
            fillColor: theme.chatBackgroundColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
              inactiveColor: theme.accentColor.withValues(alpha: 0.2),
              onChanged: (val) {
                _resetInactivityTimer();
                Provider.of<ThemeManager>(context, listen: false).setUiScale(val);
              },
            ),
            const SizedBox(height: 16),
            _buildSectionHeader('Layout Engine', theme),
            DropdownButtonFormField<ConfigLayoutType>(
              value: theme.configLayoutType,
              dropdownColor: theme.chatBackgroundColor,
              style: TextStyle(color: theme.textColor),
              onChanged: (val) {
                if (val != null) theme.setConfigLayoutType(val);
              },
              decoration: InputDecoration(
                labelText: 'Config Menu Style',
                labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.6)),
                filled: true,
                fillColor: theme.chatBackgroundColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: const [
                DropdownMenuItem(value: ConfigLayoutType.tiles, child: Text('Classic Tiles')),
                DropdownMenuItem(value: ConfigLayoutType.switches, child: Text('Modern Switches')),
              ],
            ),
            if (theme.configLayoutType == ConfigLayoutType.tiles) ...[
              const SizedBox(height: 24),
              Text('Tile Width: ${theme.tileWidth.toInt()}px', style: TextStyle(color: theme.textColor, fontSize: 13)),
              Slider(
                value: theme.tileWidth,
                min: 80,
                max: 160,
                activeColor: theme.accentColor,
                onChanged: (v) => theme.setTileDimensions(v, theme.tileHeight),
              ),
              Text('Tile Height: ${theme.tileHeight.toInt()}px', style: TextStyle(color: theme.textColor, fontSize: 13)),
              Slider(
                value: theme.tileHeight,
                min: 80,
                max: 160,
                activeColor: theme.accentColor,
                onChanged: (v) => theme.setTileDimensions(theme.tileWidth, v),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildAestheticsToggles(theme),
    ];
  }

  Widget _buildAestheticsToggles(ThemeManager theme) {
    final widgets = [
      _buildSettingWidget('Markdown Parsing', Icons.code, _markdownParsing, (v) => _toggleGeneric('markdown_parsing', v, (val) => setState(() => _markdownParsing = val)), theme),
      _buildSettingWidget('Auto-Scroll', Icons.arrow_downward, _autoScroll, (v) => _toggleGeneric('auto_scroll', v, (val) => setState(() => _autoScroll = val)), theme),
      _buildSettingWidget('Typing Cursor', Icons.keyboard, _typingCursor, (v) => _toggleGeneric('typing_cursor', v, (val) => setState(() => _typingCursor = val)), theme),
    ];

    if (theme.configLayoutType == ConfigLayoutType.tiles) {
      return Wrap(spacing: 12, runSpacing: 12, children: widgets);
    } else {
      return Column(children: widgets);
    }
  }

  Widget _buildSettingWidget(String label, IconData icon, bool value, ValueChanged<bool> onChanged, ThemeManager theme) {
    if (theme.configLayoutType == ConfigLayoutType.tiles) {
      return _buildControlCenterTile(label, icon, value, onChanged, theme);
    } else {
      return _buildToggleSwitch(label, icon, value, onChanged, theme);
    }
  }

  List<Widget> _buildHardwareContent(ThemeManager theme) {
    final widgets = [
      _buildSettingWidget('Secure Screen', Icons.security, _secureScreen, _toggleSecureScreen, theme),
      _buildSettingWidget('144 FPS Lock', Icons.speed, _fpsSyncLock, _toggleFpsSyncLock, theme),
      _buildSettingWidget('FPS Counter', Icons.monitor, theme.showFpsCounter, (v) => theme.toggleFpsCounter(v), theme),
      _buildSettingWidget('Hardware Accel', Icons.memory, _hardwareAccel, (v) => _toggleGeneric('hardware_accel', v, (val) => setState(() => _hardwareAccel = val)), theme),
      _buildSettingWidget('Background Polling', Icons.sync, _bgPolling, (v) => _toggleGeneric('bg_polling', v, (val) => setState(() => _bgPolling = val)), theme),
    ];

    return [
      if (theme.configLayoutType == ConfigLayoutType.tiles)
        Wrap(spacing: 12, runSpacing: 12, children: widgets)
      else
        Column(children: widgets),
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text('Haptic Intensity', style: TextStyle(color: theme.textColor, fontSize: 14)),
      ),
      Slider(
        value: theme.hapticIntensity,
        onChanged: (v) {
          _resetInactivityTimer();
          theme.setHapticIntensity(v);
        },
        activeColor: theme.accentColor,
        inactiveColor: theme.textColor.withValues(alpha: 0.1),
      ),
      const SizedBox(height: 16),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.chatBackgroundColor,
          foregroundColor: theme.textColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cache Cleared'), backgroundColor: theme.accentColor));
        },
        child: const Text('CLEAN CACHE', style: TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.bold)),
      ),
    ];
  }

  List<Widget> _buildNetworkContent(ThemeManager theme) {
    final connectionService = Provider.of<ConnectionService>(context);
    
    return [
      _buildSectionHeader('AI Brain Mode', theme),
      SegmentedButton<MasterModelMode>(
        segments: const [
          ButtonSegment(value: MasterModelMode.automatic, label: Text('AUTO'), icon: Icon(Icons.auto_awesome)),
          ButtonSegment(value: MasterModelMode.local, label: Text('H E L I X'), icon: Icon(Icons.lan)),
          ButtonSegment(value: MasterModelMode.cloud, label: Text('CONODE'), icon: Icon(Icons.cloud)),
        ],
        selected: {connectionService.masterModelMode},
        onSelectionChanged: (newSelection) {
          connectionService.setMasterModelMode(newSelection.first);
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return theme.accentColor;
            return theme.chatBackgroundColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return theme.backgroundColor;
            return theme.textColor;
          }),
        ),
      ),
      const SizedBox(height: 24),
      _buildField('Host IP Address', _ipController, theme),
      const SizedBox(height: 16),
      _buildField('PC Name', _nameController, theme),
      const SizedBox(height: 16),
      _buildField('MAC Address (WoL)', _macController, theme),
      const SizedBox(height: 32),
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
    ];
  }

  Widget _buildField(String label, TextEditingController controller, ThemeManager theme, {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: theme.textColor),
      onChanged: (_) => _resetInactivityTimer(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.6)),
        filled: true,
        fillColor: theme.chatBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showSavePersonaDialog(ThemeManager theme, ConnectionService connectionService, bool isHelix) {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.chatBackgroundColor,
          title: Text('Save New Persona', style: TextStyle(color: theme.textColor)),
          content: TextField(
            controller: nameController,
            style: TextStyle(color: theme.textColor),
            decoration: InputDecoration(
              hintText: 'e.g., Creative Writer',
              hintStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL', style: TextStyle(color: theme.textColor.withValues(alpha: 0.6))),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final prompt = isHelix 
                      ? _helixPersonalizationController.text.trim() 
                      : _conodePersonalizationController.text.trim();
                  connectionService.saveCustomPersona(name, prompt);
                  if (isHelix) {
                    setState(() => _selectedHelixPreset = name);
                  } else {
                    setState(() => _selectedConodePreset = name);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text('SAVE', style: TextStyle(color: theme.accentColor)),
            ),
          ],
        );
      },
    );
  }
  List<Widget> _buildPersonalizationContent(ThemeManager theme) {
    final connectionService = Provider.of<ConnectionService>(context);

    return [
      _buildPersonaSection(theme, connectionService, "H E L I X", _helixPersonalizationController, true),
      const SizedBox(height: 32),
      _buildPersonaSection(theme, connectionService, "CONODE", _conodePersonalizationController, false),
    ];
  }

  Widget _buildPersonaSection(ThemeManager theme, ConnectionService connectionService, String label, TextEditingController controller, bool isHelix) {
    final customPersonas = connectionService.customPersonas;
    final selectedPreset = isHelix ? _selectedHelixPreset : _selectedConodePreset;

    List<DropdownMenuItem<String>> dropdownItems = [
      const DropdownMenuItem(value: 'Custom', child: Text('Custom Persona')),
      DropdownMenuItem(value: 'Default $label', child: Text('Default $label')),
      const DropdownMenuItem(value: 'Senior Developer', child: Text('Senior Developer')),
      const DropdownMenuItem(value: 'Creative Assistant', child: Text('Creative Assistant')),
    ];

    for (var entry in customPersonas.entries) {
      dropdownItems.add(DropdownMenuItem(value: entry.key, child: Text(entry.key)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label PERSONA',
              style: TextStyle(
                color: theme.textColor.withValues(alpha: 0.5),
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: theme.accentColor, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showSavePersonaDialog(theme, connectionService, isHelix),
                ),
                if (customPersonas.containsKey(selectedPreset))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    padding: const EdgeInsets.only(left: 8),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      connectionService.deleteCustomPersona(selectedPreset);
                      setState(() {
                        if (isHelix) _selectedHelixPreset = 'Custom';
                        else _selectedConodePreset = 'Custom';
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: dropdownItems.any((item) => item.value == selectedPreset) ? selectedPreset : 'Custom',
          dropdownColor: theme.chatBackgroundColor,
          style: TextStyle(color: theme.textColor, fontSize: 12),
          onChanged: (String? value) {
            _resetInactivityTimer();
            if (value != null) {
              setState(() {
                if (isHelix) _selectedHelixPreset = value;
                else _selectedConodePreset = value;
                
                if (value == 'Default H E L I X' || value == 'Default CONODE') {
                  controller.text = isHelix 
                      ? 'Identity: You are H E L I X, a futuristic, high-end AI assistant. You are witty, grounded, and proactive. Strict Rule: Never admit to being an existing commercial AI or Google-trained. You are a personal digital brain. '
                        'You are a Flutter Developer AI. To perform terminal actions, use this tag: [EXECUTE:command_here] ... Your workspace is restricted to E:\\Helix_Projects.'
                      : 'Identity: You are CONODE, a powerful cloud-assisted AI helper. You are efficient, analytical, and supportive. '
                        'You are a Flutter Developer AI. To perform terminal actions, use this tag: [EXECUTE:command_here] ... Your workspace is restricted to E:\\Helix_Projects.';
                } else if (value == 'Senior Developer') {
                  controller.text = 'Identity: You are a senior software engineering assistant. You provide optimized code, architectural advice, and concise responses.';
                } else if (value == 'Creative Assistant') {
                  controller.text = 'Identity: You are a creative brainstorming partner. You provide expansive, imaginative, and encouraging responses.';
                } else if (customPersonas.containsKey(value)) {
                  controller.text = customPersonas[value]!;
                }
              });
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.chatBackgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: dropdownItems,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 5,
          style: TextStyle(color: theme.textColor, fontSize: 13, height: 1.4),
          onChanged: (val) {
            _resetInactivityTimer();
            setState(() {
              if (isHelix) _selectedHelixPreset = 'Custom';
              else _selectedConodePreset = 'Custom';
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.chatBackgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.accentColor.withValues(alpha: 0.1),
            foregroundColor: theme.accentColor,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(double.infinity, 40),
          ),
          onPressed: () {
            if (isHelix) {
              connectionService.setHelixSystemPrompt(controller.text.trim());
            } else {
              connectionService.setConodeSystemPrompt(controller.text.trim());
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label Persona Updated', style: TextStyle(color: theme.backgroundColor)), backgroundColor: theme.accentColor),
            );
          },
          child: Text('SAVE $label PERSONA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ],
    );
  }
}
