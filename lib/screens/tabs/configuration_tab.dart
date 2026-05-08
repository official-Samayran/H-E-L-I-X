import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:ui';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
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
  
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;
  Timer? _inactivityTimer;

  // Toggle states
  bool _secureScreen = false;
  bool _fpsSyncLock = false;
  bool _markdownParsing = true;
  bool _autoScroll = true;
  bool _typingCursor = true;
  bool _hardwareAccel = true;
  bool _bgPolling = true;
  
  final PageController _pageController = PageController(viewportFraction: 1.0);
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
    
    _loadSettings();
    _authenticate();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _secureScreen = prefs.getBool('secure_screen_protocol') ?? false;
      _fpsSyncLock = prefs.getBool('fps_sync_lock') ?? false;
      _markdownParsing = prefs.getBool('markdown_parsing') ?? true;
      _autoScroll = prefs.getBool('auto_scroll') ?? true;
      _typingCursor = prefs.getBool('typing_cursor') ?? true;
      _hardwareAccel = prefs.getBool('hardware_accel') ?? true;
      _bgPolling = prefs.getBool('bg_polling') ?? true;
    });
  }

  Future<void> _authenticate() async {
    // Temporarily bypassing biometric check to resolve environment-specific build errors
    setState(() {
      _isAuthenticated = true;
      _isAuthenticating = false;
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      if (mounted) setState(() => _isAuthenticated = false);
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

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    
    if (_isAuthenticating) return Center(child: CircularProgressIndicator(color: theme.accentColor));
    if (!_isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: theme.accentColor),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: theme.accentColor),
              onPressed: _authenticate,
              child: const Text('UNLOCK SETTINGS'),
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
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildConnectionContent(theme),
              _buildPersonalizationContent(theme),
              _buildThemesContent(theme),
              _buildUIContent(theme),
              _buildSystemContent(theme),
            ],
          ),
        ),
        // Sidebar with Drag Switcher
        GestureDetector(
          onVerticalDragUpdate: (details) {
            final double dragPosition = details.localPosition.dy;
            final double sidebarHeight = context.size?.height ?? 600;
            final int targetPage = ((dragPosition / sidebarHeight) * 5).clamp(0, 4).toInt();
            if (targetPage != _currentPage) {
              theme.triggerScrollTick();
              _pageController.animateToPage(targetPage, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
            }
          },
          child: Container(
            width: 44,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: theme.textColor.withValues(alpha: 0.05))),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(0, Icons.wifi, theme),
                const SizedBox(height: 12),
                _buildDot(1, Icons.psychology, theme),
                const SizedBox(height: 12),
                _buildDot(2, Icons.palette, theme),
                const SizedBox(height: 12),
                _buildDot(3, Icons.touch_app, theme),
                const SizedBox(height: 12),
                _buildDot(4, Icons.settings, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index, IconData icon, ThemeManager theme) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      onTap: () {
        theme.triggerSelectionHaptic();
        _pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: isSelected ? 14 : 10, color: isSelected ? theme.backgroundColor : theme.textColor.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildPageWrapper(ThemeManager theme, String title, IconData icon, String subtitle, List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.accentColor, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: theme.textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  // CONNECTION CONTENT
  Widget _buildConnectionContent(ThemeManager theme) {
    final provider = Provider.of<BaseConnectionProvider>(context);
    final connection = Provider.of<ConnectionService>(context);
    
    return _buildPageWrapper(
      theme, 'CONNECTIVITY', Icons.wifi, 'Manage server endpoints and API keys.',
      [
        AdaptiveConfigCard(
          height: 480 * theme.cardHeightMultiplier,
          front: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildTextField(_ipController, 'HELIX IP (Host)', (v) => provider.setHostIP(v), theme),
                const SizedBox(height: 16),
                _buildTextField(_apiKeyController, 'CONODE API KEY', (v) => connection.setGeminiApiKey(v), theme, isPassword: true),
                const Spacer(),
                _buildSettingTile('Automatic Fallback', Icons.auto_mode, connection.masterModelMode == MasterModelMode.automatic, 
                  (v) => connection.setMasterModelMode(v ? MasterModelMode.automatic : MasterModelMode.local), theme),
              ],
            ),
          ),
          back: const Center(child: Text('ADVANCED NETWORK LOGS')),
        ),
      ],
    );
  }

  // PERSONALIZATION CONTENT
  Widget _buildPersonalizationContent(ThemeManager theme) {
    final connection = Provider.of<ConnectionService>(context);
    return _buildPageWrapper(
      theme, 'AI PERSONAS', Icons.psychology, 'Define behavior and system instructions.',
      [
        AdaptiveConfigCard(
          height: 500 * theme.cardHeightMultiplier,
          front: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSectionHeader('HELIX MASTER', theme),
                _buildTextField(_helixPersonalizationController, 'System Prompt', (v) => connection.setHelixSystemPrompt(v), theme, maxLines: 3),
                const SizedBox(height: 24),
                _buildSectionHeader('CONODE HELPER', theme),
                _buildTextField(_conodePersonalizationController, 'System Prompt', (v) => connection.setConodeSystemPrompt(v), theme, maxLines: 3),
              ],
            ),
          ),
          back: const Center(child: Text('PERSONA PRESETS')),
        ),
      ],
    );
  }

  // THEMES CONTENT
  Widget _buildThemesContent(ThemeManager theme) {
    return _buildPageWrapper(
      theme, 'THEME ENGINE', Icons.palette, 'Curated styles and custom composition.',
      [
        AdaptiveConfigCard(
          height: 500 * theme.cardHeightMultiplier,
          front: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('CATEGORIES', theme),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
                    children: [
                      _buildCatTile('90s', Icons.videogame_asset, theme),
                      _buildCatTile('Gaming', Icons.sports_esports, theme),
                      _buildCatTile('Simple', Icons.minimize, theme),
                      _buildCatTile('Aesthetic', Icons.auto_awesome, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionTile('CUSTOM COMPOSER', Icons.brush, theme),
              ],
            ),
          ),
          back: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSectionHeader('MIX & MATCH', theme),
                _buildMixOption('UI Tiles', 'Minecraft', theme),
                _buildMixOption('Font', 'Helix (Teko)', theme),
                _buildMixOption('Background', 'Glassmorphic', theme),
                const Spacer(),
                ElevatedButton(onPressed: () {}, child: const Text('SAVE DESIGN')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // UI CONTENT
  Widget _buildUIContent(ThemeManager theme) {
    return _buildPageWrapper(
      theme, 'INTERFACE', Icons.touch_app, 'Scales, dimensions, and transitions.',
      [
        AdaptiveConfigCard(
          height: 520 * theme.cardHeightMultiplier,
          front: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSlider('UI Scale', theme.uiScale, 0.8, 1.2, (v) => theme.setUiScale(v), theme),
                _buildSlider('Tile Size', theme.tileWidth / 150, 0.6, 1.4, (v) => theme.setTileDimensions(v * 150, v * 150), theme),
                _buildSlider('Card Space', theme.cardHeightMultiplier, 0.7, 1.3, (v) => theme.setCardDimensions(v, v), theme),
                const Spacer(),
                _buildActionTile('TRANSITION EFFECTS', Icons.animation, theme),
              ],
            ),
          ),
          back: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildAnimOption('Flip', AnimationType.flip, theme),
                _buildAnimOption('Slide / Shift', AnimationType.slide, theme),
                _buildAnimOption('Morph', AnimationType.morph, theme),
                _buildAnimOption('Glass Reveal', AnimationType.blur, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // SYSTEM CONTENT
  Widget _buildSystemContent(ThemeManager theme) {
    return _buildPageWrapper(
      theme, 'SYSTEM', Icons.settings, 'Hardware hooks and security protocols.',
      [
        AdaptiveConfigCard(
          height: 480 * theme.cardHeightMultiplier,
          front: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSettingTile('Secure Screen', Icons.security, _secureScreen, (v) => setState(() => _secureScreen = v), theme),
                _buildSettingTile('144 FPS Lock', Icons.bolt, _fpsSyncLock, (v) => setState(() => _fpsSyncLock = v), theme),
                _buildSettingTile('FPS Counter', Icons.monitor, theme.showFpsCounter, (v) => theme.toggleFpsCounter(v), theme),
                const Spacer(),
                _buildSlider('Haptics', theme.hapticIntensity, 0, 1.0, (v) => theme.setHapticIntensity(v), theme),
              ],
            ),
          ),
          back: const Center(child: Text('CACHE & LOGS')),
        ),
      ],
    );
  }

  // HELPERS
  Widget _buildSectionHeader(String title, ThemeManager theme) {
    return Text(title, style: TextStyle(color: theme.textColor.withValues(alpha: 0.4), fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.bold));
  }

  Widget _buildTextField(TextEditingController ctrl, String label, ValueChanged<String> onChanged, ThemeManager theme, {bool isPassword = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword,
      maxLines: maxLines,
      style: TextStyle(color: theme.textColor, fontSize: 13),
      onChanged: (v) { _resetInactivityTimer(); onChanged(v); },
      decoration: InputDecoration(
        labelText: label, labelStyle: TextStyle(color: theme.textColor.withValues(alpha: 0.5)),
        filled: true, fillColor: theme.textColor.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, ValueChanged<double> onChanged, ThemeManager theme) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: theme.textColor, fontSize: 12)),
          Text(val.toStringAsFixed(2), style: TextStyle(color: theme.accentColor, fontSize: 11, fontFamily: 'monospace')),
        ]),
        Slider(value: val.clamp(min, max), min: min, max: max, onChanged: onChanged, activeColor: theme.accentColor),
      ],
    );
  }

  Widget _buildSettingTile(String label, IconData icon, bool value, ValueChanged<bool> onChanged, ThemeManager theme) {
    return ListTile(
      leading: Icon(icon, color: theme.accentColor, size: 20),
      title: Text(label, style: TextStyle(color: theme.textColor, fontSize: 14)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: theme.accentColor),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCatTile(String label, IconData icon, ThemeManager theme) {
    return Container(
      decoration: BoxDecoration(color: theme.textColor.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(12)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: theme.accentColor, size: 20),
        Text(label, style: TextStyle(color: theme.textColor, fontSize: 11, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildMixOption(String label, String value, ThemeManager theme) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: theme.textColor.withValues(alpha: 0.6), fontSize: 12)),
      Text(value, style: TextStyle(color: theme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildAnimOption(String label, AnimationType type, ThemeManager theme) {
    final isSelected = theme.animationType == type;
    return GestureDetector(
      onTap: () => theme.setAnimationType(type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor.withValues(alpha: 0.1) : theme.textColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? theme.accentColor : Colors.transparent),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: isSelected ? theme.accentColor : theme.textColor, fontSize: 13, fontWeight: FontWeight.bold)),
          if (isSelected) Icon(Icons.check_circle, color: theme.accentColor, size: 16),
        ]),
      ),
    );
  }

  Widget _buildActionTile(String label, IconData icon, ThemeManager theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.accentColor.withValues(alpha: 0.2))),
      child: Row(children: [
        Icon(icon, color: theme.accentColor, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }
}

class AdaptiveConfigCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final double height;
  const AdaptiveConfigCard({super.key, required this.front, required this.back, required this.height});

  @override
  State<AdaptiveConfigCard> createState() => _AdaptiveConfigCardState();
}

class _AdaptiveConfigCardState extends State<AdaptiveConfigCard> {
  bool _isFlipped = false;

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final anim = theme.animationType;

    return Center(
      child: GestureDetector(
        onTap: () { setState(() => _isFlipped = !_isFlipped); theme.triggerSelectionHaptic(); },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          width: MediaQuery.of(context).size.width * 0.9 * theme.cardWidthMultiplier,
          height: widget.height,
          decoration: BoxDecoration(
            color: theme.chatBackgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.textColor.withValues(alpha: 0.1)),
          ),
          child: ClipRRect(borderRadius: BorderRadius.circular(24), child: _buildContent(anim)),
        ),
      ),
    );
  }

  Widget _buildContent(AnimationType type) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        switch (type) {
          case AnimationType.slide:
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuart,
                  left: _isFlipped ? -width : 0,
                  width: width,
                  height: constraints.maxHeight,
                  child: widget.front,
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuart,
                  left: _isFlipped ? 0 : width,
                  width: width,
                  height: constraints.maxHeight,
                  child: widget.back,
                ),
              ],
            );
          case AnimationType.morph:
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a.drive(Tween(begin: 0.95, end: 1.0)), child: c)),
              child: _isFlipped ? KeyedSubtree(key: const ValueKey('b'), child: widget.back) : KeyedSubtree(key: const ValueKey('f'), child: widget.front),
            );
          case AnimationType.blur:
            return Stack(children: [
              widget.front,
              if (_isFlipped) BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.black.withValues(alpha: 0.2), child: widget.back)),
            ]);
          default:
            return TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: _isFlipped ? pi : 0),
              duration: const Duration(milliseconds: 500),
              builder: (context, double val, _) {
                final isBack = val > pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(val),
                  child: isBack ? Transform(alignment: Alignment.center, transform: Matrix4.identity()..rotateY(pi), child: widget.back) : widget.front,
                );
              },
            );
        }
      }
    );
  }
}
