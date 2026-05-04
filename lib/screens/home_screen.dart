import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:battery_plus/battery_plus.dart';
import '../theme/theme_manager.dart';
import '../theme/app_theme.dart';
import '../services/connection_service.dart';
import 'tabs/chat_tab.dart';
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
              // Sync Gear
              AnimatedBuilder(
                animation: _gearController,
                builder: (_, child) => Transform.rotate(
                  angle: connectionService.isTyping ? _gearController.value * 2 * 3.14159 : 0,
                  child: Icon(Icons.settings, size: 16, color: themeManager.accentColor),
                ),
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
        child: Column(
          children: [
            _buildTopHUD(themeManager, connectionService),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                children: const [
                  ChatTab(),
                  SystemDashboardTab(),
                  ConfigurationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: themeManager.currentThemeType == AppThemeType.oled 
              ? Colors.black 
              : themeManager.chatBackgroundColor,
          elevation: 8,
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: themeManager.accentColor,
          unselectedItemColor: themeManager.textColor.withOpacity(0.4),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Config',
            ),
          ],
        ),
      ),
    );
  }
}
