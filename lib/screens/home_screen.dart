import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../theme/theme_manager.dart';
import '../services/connection_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/system_dashboard_tab.dart';
import 'tabs/configuration_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  final Battery _battery = Battery();
  int _batteryLevel = 100;
  Timer? _timer;
  late AnimationController _gearController;
  
  int? _peekingTabIndex;
  double _peekDragAmount = 0.0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _initBattery();
    _gearController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initBattery() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _batteryLevel = level);
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    _gearController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildTopHUD(ThemeManager themeManager, ConnectionService connectionService) {
    final isLocal = connectionService.isLocalAvailable;
    final int simulatedPing = isLocal ? 24 : 180;
    Color pingColor = simulatedPing < 50 ? Colors.greenAccent : (simulatedPing < 150 ? Colors.yellowAccent : Colors.redAccent);
    String timeString = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: themeManager.currentThemeType == AppThemeType.oled ? Colors.black : Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'H E L I X',
            style: TextStyle(
              color: themeManager.textColor,
              letterSpacing: 12,
              fontSize: 20,
              fontWeight: FontWeight.w200,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ping
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: pingColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('$simulatedPing ms', style: TextStyle(color: themeManager.textColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              // Battery & Time
              Row(
                children: [
                  Icon(Icons.battery_std, size: 14, color: themeManager.textColor.withOpacity(0.7)),
                  const SizedBox(width: 4),
                  Text('$_batteryLevel%', style: TextStyle(color: themeManager.textColor.withOpacity(0.7), fontSize: 12)),
                  const SizedBox(width: 12),
                  Text(timeString, style: TextStyle(color: themeManager.textColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              )
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: themeManager.textColor.withOpacity(0.1), height: 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final connectionService = Provider.of<ConnectionService>(context);

    return Scaffold(
      backgroundColor: themeManager.backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompressed = constraints.maxHeight < 400;
            return Column(
              children: [
                if (!isCompressed) _buildTopHUD(themeManager, connectionService),
                Expanded(
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        children: const [
                          HomeTab(),
                          SystemDashboardTab(),
                          ConfigurationTab(),
                        ],
                      ),
                      if (_peekingTabIndex != null)
                        _buildPeekOverlay(),
                    ],
                  ),
                ),
              ],
            );
          }
        ),
      ),
      bottomNavigationBar: _buildGestureTabBar(themeManager),
    );
  }

  Widget _buildPeekOverlay() {
    double scale = 0.8 + (_peekDragAmount < 0 ? (_peekDragAmount / -500).clamp(0.0, 0.2) : 0);
    
    Widget targetPage;
    switch (_peekingTabIndex) {
      case 0: targetPage = const HomeTab(); break;
      case 1: targetPage = const SystemDashboardTab(); break;
      case 2: targetPage = const ConfigurationTab(); break;
      default: targetPage = const SizedBox();
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black87,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: scale),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: IgnorePointer(child: targetPage),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGestureTabBar(ThemeManager themeManager) {
    return Container(
      color: themeManager.currentThemeType == AppThemeType.oled 
          ? Colors.black 
          : themeManager.chatBackgroundColor,
      height: 80,
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildGestureTabItem(0, Icons.home_outlined, Icons.home, 'Home', themeManager),
          _buildGestureTabItem(1, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', themeManager),
          _buildGestureTabItem(2, Icons.settings_outlined, Icons.settings, 'Config', themeManager),
        ],
      ),
    );
  }

  Widget _buildGestureTabItem(int index, IconData iconOutlined, IconData iconSolid, String label, ThemeManager themeManager) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? themeManager.accentColor : themeManager.textColor.withOpacity(0.4);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      onLongPressStart: (details) {
        setState(() {
          _peekingTabIndex = index;
          _peekDragAmount = 0.0;
        });
      },
      onLongPressMoveUpdate: (details) {
        setState(() {
          _peekDragAmount = details.localOffsetFromOrigin.dy;
        });
      },
      onLongPressEnd: (details) {
        if (_peekDragAmount < -40.0) {
          // Swipe threshold reached, jump to page
          _onTabTapped(index);
        }
        setState(() {
          _peekingTabIndex = null;
          _peekDragAmount = 0.0;
        });
      },
      child: Container(
        color: Colors.transparent, // needed for gesture detector area
        width: 80,
        height: 60,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? themeManager.accentColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(isSelected ? iconSolid : iconOutlined, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
