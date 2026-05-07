import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info2/system_info2.dart';

import '../../theme/theme_manager.dart';
import '../../services/telemetry_service.dart';

class SystemDashboardTab extends StatefulWidget {
  const SystemDashboardTab({super.key});

  @override
  State<SystemDashboardTab> createState() => _SystemDashboardTabState();
}

class _SystemDashboardTabState extends State<SystemDashboardTab> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final telemetry = Provider.of<TelemetryService>(context);
    final isOnline = telemetry.isWsConnected;

    final pcCard = const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Center(child: PCTelemetryCard()),
    );
    final phoneCard = const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Center(child: PhoneTelemetryCard()),
    );

    final cards = isOnline ? [pcCard, phoneCard] : [phoneCard, pcCard];

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
            children: cards,
          ),
        ),
        Container(
          width: 32,
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0, theme),
              const SizedBox(height: 8),
              _buildDot(1, theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot(int index, ThemeManager theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: 8,
      height: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? theme.accentColor : theme.textColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ---------------------------------------------------------
// 3D FLIP GLASS CARD
// ---------------------------------------------------------
class FlipGlassCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool isFlipped;
  final double height;

  const FlipGlassCard({
    super.key,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.height,
  });

  @override
  State<FlipGlassCard> createState() => _FlipGlassCardState();
}

class _FlipGlassCardState extends State<FlipGlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.isFlipped) _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(FlipGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * pi;
        final isBack = angle > pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.currentThemeType == AppThemeType.oled
                  ? Colors.black
                  : theme.chatBackgroundColor.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.textColor.withValues(alpha: 0.05),
                width: 1,
              ),
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
                child: isBack
                    ? Transform(
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: widget.back,
                      )
                    : widget.front,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------
// PC TELEMETRY CARD
// ---------------------------------------------------------
class PCTelemetryCard extends StatefulWidget {
  const PCTelemetryCard({super.key});

  @override
  State<PCTelemetryCard> createState() => _PCTelemetryCardState();
}

class _PCTelemetryCardState extends State<PCTelemetryCard> {
  bool _isFlipped = false;
  int _backViewType = 0; // 0: CPU, 1: Memory, 2: Hardware
  final DateTime _startTime = DateTime.now();

  void _flipTo(int type) {
    Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
    if (_isFlipped && _backViewType == type) {
      setState(() => _isFlipped = false);
    } else {
      setState(() {
        _backViewType = type;
        _isFlipped = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final telemetry = Provider.of<TelemetryService>(context);

    return FlipGlassCard(
      isFlipped: _isFlipped,
      height: 480,
      front: _buildFront(theme, telemetry),
      back: _buildBack(theme, telemetry),
    );
  }

  Widget _buildFront(ThemeManager theme, TelemetryService telemetry) {
    final isOnline = telemetry.isWsConnected;
    final data = telemetry.currentData;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PC TELEMETRY',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.greenAccent : Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isOnline ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isOnline)
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, _) {
                        final uptime = DateTime.now().difference(_startTime);
                        final hours = uptime.inHours.toString().padLeft(2, '0');
                        final minutes = (uptime.inMinutes % 60).toString().padLeft(2, '0');
                        final seconds = (uptime.inSeconds % 60).toString().padLeft(2, '0');
                        return Text(
                          '$hours:$minutes:$seconds',
                          style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'monospace'),
                        );
                      },
                    )
                  else
                    const Text(
                      'DISCONNECTED',
                      style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              _buildActionButton(theme, 'CPU PROCS', Icons.memory, () => _flipTo(0)),
              const SizedBox(width: 12),
              _buildActionButton(theme, 'MEM PROCS', Icons.memory_outlined, () => _flipTo(1)),
              const SizedBox(width: 12),
              _buildActionButton(theme, 'HARDWARE', Icons.dns_outlined, () => _flipTo(2)),
            ],
          ),
          const SizedBox(height: 24),
          // Graphs
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildMiniGraph(theme, 'CPU', data.cpu, telemetry.history.map((e) => e.cpu).toList(), Colors.cyanAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMiniGraph(theme, 'RAM', data.ram, telemetry.history.map((e) => e.ram).toList(), Colors.greenAccent)),
                const SizedBox(width: 16),
                Expanded(child: _buildMiniGraph(theme, 'GPU', data.gpu, telemetry.history.map((e) => e.gpu).toList(), Colors.purpleAccent)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Mini Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric(theme, 'TEMP', '${data.temp.toStringAsFixed(1)}°C'),
              _buildMiniMetric(theme, 'FAN', '${data.fanSpeed.toInt()} RPM'),
              _buildMiniMetric(theme, 'DISK', '${data.disk.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(ThemeManager theme, TelemetryService telemetry) {
    final data = telemetry.currentData;
    String title = '';
    Widget content = const SizedBox();

    if (_backViewType == 0) {
      title = 'CPU PROCESSES';
      content = _buildProcessView(theme, 'Highest CPU Allocation', data.topCpuApp, data.cpu);
    } else if (_backViewType == 1) {
      title = 'MEMORY PROCESSES';
      content = _buildProcessView(theme, 'Highest RAM Allocation', data.topRamApp, data.ram);
    } else if (_backViewType == 2) {
      title = 'HARDWARE ANALYTICS';
      content = _buildHardwareView(theme, data);
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () {
                  Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
                  setState(() => _isFlipped = false);
                },
              ),
              Text(
                title,
                style: TextStyle(color: theme.textColor, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildProcessView(ThemeManager theme, String label, String appName, double usage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.memory, size: 64, color: theme.accentColor.withValues(alpha: 0.5)),
        const SizedBox(height: 24),
        Text(label, style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(appName, style: TextStyle(color: theme.textColor, fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
          ),
          child: Text('System Usage: ${usage.toStringAsFixed(1)}%', style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildHardwareView(ThemeManager theme, TelemetryData data) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildHardwareSection(theme, 'STORAGE (MAIN DRIVE)', Icons.storage, [
          _buildHardwareStat(theme, 'Usage', '${data.disk.toStringAsFixed(1)}%'),
          _buildHardwareStat(theme, 'Health', 'Good'),
          _buildHardwareStat(theme, 'Temp', '${data.temp.toStringAsFixed(1)}°C'),
        ]),
        const SizedBox(height: 16),
        _buildHardwareSection(theme, 'PERIPHERALS', Icons.mouse, [
          _buildHardwareStat(theme, 'Devices', 'Data Stream Unavailable'),
        ]),
      ],
    );
  }

  Widget _buildHardwareSection(ThemeManager theme, String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.chatBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.textColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.accentColor, size: 16),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHardwareStat(ThemeManager theme, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12)),
          Text(val, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButton(ThemeManager theme, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.accentColor, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: theme.textColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniGraph(ThemeManager theme, String label, double currentVal, List<double> history, Color color) {
    final spots = history.isEmpty 
        ? [const FlSpot(0, 0)] 
        : List.generate(history.length, (index) => FlSpot(index.toDouble(), history[index]));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('${currentVal.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.chatBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 60,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: color,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniMetric(ThemeManager theme, String label, String val) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(val, style: TextStyle(color: theme.textColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}

// ---------------------------------------------------------
// PHONE TELEMETRY CARD
// ---------------------------------------------------------
class PhoneTelemetryCard extends StatefulWidget {
  const PhoneTelemetryCard({super.key});

  @override
  State<PhoneTelemetryCard> createState() => _PhoneTelemetryCardState();
}

class _PhoneTelemetryCardState extends State<PhoneTelemetryCard> {
  bool _isFlipped = false;
  int _backViewType = 0; // 0: Connectivity, 1: Storage

  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  
  int _batteryLevel = 100;
  List<ConnectivityResult> _connectivityStatus = [ConnectivityResult.none];
  String _deviceName = "Unknown Device";
  int _freeRam = 0;
  int _totalRam = 0;

  Timer? _pollingTimer;
  StreamSubscription? _batterySubscription;
  StreamSubscription? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initPhoneData();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollRam());
  }

  Future<void> _initPhoneData() async {
    try {
      _batteryLevel = await _battery.batteryLevel;
      _connectivityStatus = await _connectivity.checkConnectivity();
      
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        _deviceName = "${info.manufacturer} ${info.model}";
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        _deviceName = info.name;
      }
      
      _pollRam();

      // Listeners
      _batterySubscription = _battery.onBatteryStateChanged.listen((_) async {
        if (mounted) {
          final level = await _battery.batteryLevel;
          if (mounted) setState(() => _batteryLevel = level);
        }
      });

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
        if (mounted) {
          setState(() => _connectivityStatus = results);
        }
      });
    } catch (e) {
      debugPrint("Phone telemetry init error: $e");
    }
  }

  void _pollRam() {
    if (!mounted) return;
    try {
      setState(() {
        _freeRam = SysInfo.getFreePhysicalMemory();
        _totalRam = SysInfo.getTotalPhysicalMemory();
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _batterySubscription?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _flipTo(int type) {
    Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
    if (_isFlipped && _backViewType == type) {
      setState(() => _isFlipped = false);
    } else {
      setState(() {
        _backViewType = type;
        _isFlipped = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);

    return FlipGlassCard(
      isFlipped: _isFlipped,
      height: 480,
      front: _buildFront(theme),
      back: _buildBack(theme),
    );
  }

  Widget _buildFront(ThemeManager theme) {
    final hasWifi = _connectivityStatus.contains(ConnectivityResult.wifi);
    final hasMobile = _connectivityStatus.contains(ConnectivityResult.mobile);
    final isOnline = hasWifi || hasMobile;

    double ramUsage = 0;
    if (_totalRam > 0) {
      ramUsage = ((_totalRam - _freeRam) / _totalRam) * 100;
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PHONE TELEMETRY',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.greenAccent : Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isOnline ? Colors.greenAccent.withValues(alpha: 0.5) : Colors.redAccent.withValues(alpha: 0.5),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_batteryLevel%',
                    style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(_deviceName, style: TextStyle(color: theme.accentColor, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          // Action Buttons
          Row(
            children: [
              _buildActionButton(theme, 'CONNECTIVITY', Icons.wifi, () => _flipTo(0)),
              const SizedBox(width: 12),
              _buildActionButton(theme, 'STORAGE', Icons.sd_storage_outlined, () => _flipTo(1)),
            ],
          ),
          const SizedBox(height: 24),
          // Status Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusPill(theme, 'Wi-Fi', hasWifi),
                const SizedBox(width: 8),
                _buildStatusPill(theme, 'Mobile', hasMobile),
                const SizedBox(width: 8),
                _buildStatusPill(theme, 'Bluetooth', _connectivityStatus.contains(ConnectivityResult.bluetooth)),
                const SizedBox(width: 8),
                _buildStatusPill(theme, 'VPN', _connectivityStatus.contains(ConnectivityResult.vpn)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Live Telemetry
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.chatBackgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPhoneMetricRow(theme, 'RAM Usage', '${ramUsage.toStringAsFixed(1)}%', Icons.memory),
                  _buildPhoneMetricRow(theme, 'Free RAM', '${(_freeRam / 1024 / 1024 / 1024).toStringAsFixed(2)} GB', Icons.cleaning_services),
                  _buildPhoneMetricRow(theme, 'Connection', hasWifi ? 'Wi-Fi' : (hasMobile ? 'Cellular' : 'None'), Icons.signal_cellular_alt),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBack(ThemeManager theme) {
    String title = '';
    Widget content = const SizedBox();

    if (_backViewType == 0) {
      title = 'CONNECTIVITY ANALYTICS';
      content = _buildConnectivityView(theme);
    } else if (_backViewType == 1) {
      title = 'STORAGE ANALYTICS';
      content = _buildStorageView(theme);
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () {
                  Provider.of<ThemeManager>(context, listen: false).triggerHaptic();
                  setState(() => _isFlipped = false);
                },
              ),
              Text(
                title,
                style: TextStyle(color: theme.textColor, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildConnectivityView(ThemeManager theme) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        _buildPhoneMetricRow(theme, 'Active Interfaces', _connectivityStatus.map((e) => e.name).join(', '), Icons.device_hub),
        const SizedBox(height: 16),
        _buildPhoneMetricRow(theme, 'Network Integrity', _connectivityStatus.contains(ConnectivityResult.none) ? 'Degraded' : 'Nominal', Icons.security),
      ],
    );
  }

  Widget _buildStorageView(ThemeManager theme) {
    // We don't have deep storage analytics without platform channels. We represent RAM mapping here.
    double ramUsage = 0;
    if (_totalRam > 0) {
      ramUsage = ((_totalRam - _freeRam) / _totalRam) * 100;
    }
    
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  color: theme.accentColor,
                  value: ramUsage,
                  title: '${ramUsage.toStringAsFixed(0)}%',
                  radius: 20,
                  titleStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.backgroundColor),
                ),
                PieChartSectionData(
                  color: theme.textColor.withValues(alpha: 0.1),
                  value: 100 - ramUsage,
                  title: '',
                  radius: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('MEMORY ALLOCATION', style: TextStyle(color: theme.textColor.withValues(alpha: 0.5), fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 16),
        _buildPhoneMetricRow(theme, 'Used Memory', '${((_totalRam - _freeRam) / 1024 / 1024 / 1024).toStringAsFixed(2)} GB', Icons.pie_chart),
        _buildPhoneMetricRow(theme, 'Free Memory', '${(_freeRam / 1024 / 1024 / 1024).toStringAsFixed(2)} GB', Icons.pie_chart_outline),
      ],
    );
  }

  Widget _buildActionButton(ThemeManager theme, String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: theme.accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.accentColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: theme.accentColor, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: theme.textColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(ThemeManager theme, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.greenAccent.withValues(alpha: 0.1) : theme.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? Colors.greenAccent.withValues(alpha: 0.3) : Colors.transparent),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.greenAccent : theme.textColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
           Text(label, style: TextStyle(color: isActive ? Colors.greenAccent : theme.textColor.withValues(alpha: 0.5), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPhoneMetricRow(ThemeManager theme, String label, String val, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.accentColor, size: 18),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: theme.textColor.withValues(alpha: 0.7), fontSize: 12)),
        const Spacer(),
        Text(val, style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
      ],
    );
  }
}
