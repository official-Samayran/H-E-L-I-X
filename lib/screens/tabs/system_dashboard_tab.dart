import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/theme_manager.dart';
import '../../widgets/battery_analytics.dart';
import '../../services/telemetry_service.dart';
import '../../services/connection_service.dart';
import '../sprint_log_screen.dart';

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:system_info2/system_info2.dart';

class SystemDashboardTab extends StatefulWidget {
  const SystemDashboardTab({super.key});

  @override
  State<SystemDashboardTab> createState() => _SystemDashboardTabState();
}

class _SystemDashboardTabState extends State<SystemDashboardTab> {
  bool _showMobileTelemetry = false;
  Map<String, String> _mobileSpecs = {};

  @override
  void initState() {
    super.initState();
    _fetchMobileSpecs();
  }

  Future<void> _fetchMobileSpecs() async {
    final deviceInfo = DeviceInfoPlugin();
    String model = "Unknown";
    String kernel = "Unknown";
    
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      model = "${androidInfo.manufacturer} ${androidInfo.model}";
      kernel = androidInfo.version.release;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      model = iosInfo.name;
      kernel = iosInfo.systemVersion;
    }

    int freeRam = 0;
    int totalRam = 0;
    try {
      freeRam = SysInfo.getFreePhysicalMemory();
      totalRam = SysInfo.getTotalPhysicalMemory();
    } catch (_) {}
    
    if (mounted) {
      setState(() {
        _mobileSpecs = {
          "Model": model,
          "Kernel/OS": kernel,
          "Free RAM": freeRam > 0 ? "${(freeRam / 1024 / 1024 / 1024).toStringAsFixed(2)} GB" : "N/A",
          "Total RAM": totalRam > 0 ? "${(totalRam / 1024 / 1024 / 1024).toStringAsFixed(2)} GB" : "N/A",
        };
      });
    }
  }

  void _showTop10Popup(BuildContext context, ThemeManager theme, String resourceName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.chatBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Top 10 Processes ($resourceName)',
                style: TextStyle(color: theme.textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    final names = ['chrome.exe', 'Code.exe', 'Discord.exe', 'Spotify.exe', 'explorer.exe', 'HelixEngine.exe', 'Dwm.exe', 'SearchApp.exe', 'Taskmgr.exe', 'svchost.exe'];
                    return ListTile(
                      leading: Text('#${index + 1}', style: TextStyle(color: theme.accentColor)),
                      title: Text(names[index], style: TextStyle(color: theme.textColor, fontFamily: 'monospace')),
                      trailing: Text('${(25.0 - index * 2.1).toStringAsFixed(1)}%', style: TextStyle(color: theme.textColor.withOpacity(0.7))),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final connection = Provider.of<ConnectionService>(context);
    
    return RefreshIndicator(
      onRefresh: () async {
        // Trigger manual refresh or reconnect logic here
        await Future.delayed(const Duration(seconds: 1));
      },
      color: themeManager.accentColor,
      backgroundColor: themeManager.chatBackgroundColor,
      child: StreamBuilder<int>(
        stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
        builder: (context, snapshot) {
          final telemetry = Provider.of<TelemetryService>(context, listen: false);

          if (!telemetry.isWsConnected && !connection.isLocalAvailable) {
            return _buildOfflineState(themeManager);
          }

          final history = telemetry.history;
          final current = telemetry.currentData;
          
          List<FlSpot> cpuSpots = [];
          List<FlSpot> ramSpots = [];
          List<FlSpot> gpuSpots = [];
          
          for (int i = 0; i < history.length; i++) {
            cpuSpots.add(FlSpot(i.toDouble(), history[i].cpu));
            ramSpots.add(FlSpot(i.toDouble(), history[i].ram));
            gpuSpots.add(FlSpot(i.toDouble(), history[i].gpu));
          }

          final bool isLoading = history.isEmpty;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SYSTEM TELEMETRY',
                      style: TextStyle(
                        color: themeManager.textColor,
                        fontSize: 18,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: themeManager.backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: themeManager.accentColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showMobileTelemetry = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_showMobileTelemetry ? themeManager.accentColor.withOpacity(0.2) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
                              ),
                              child: Text('PC', style: TextStyle(color: !_showMobileTelemetry ? themeManager.accentColor : themeManager.textColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _showMobileTelemetry = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _showMobileTelemetry ? themeManager.accentColor.withOpacity(0.2) : Colors.transparent,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                              ),
                              child: Text('MOBILE', style: TextStyle(color: _showMobileTelemetry ? themeManager.accentColor : themeManager.textColor.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SprintLogScreen()));
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: themeManager.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeManager.accentColor.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, color: themeManager.accentColor),
                        const SizedBox(width: 12),
                        Text(
                          'VIEW HISTORY OF HELIX',
                          style: TextStyle(
                            color: themeManager.accentColor,
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                const SizedBox(height: 24),
                
                if (_showMobileTelemetry) ...[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: _mobileSpecs.entries.map((e) => _buildInfoTile(e.key, e.value, Icons.memory, themeManager, false)).toList(),
                  ),
                ] else ...[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      _buildInfoTile('Top CPU', current.topCpuApp, Icons.memory, themeManager, isLoading),
                      _buildInfoTile('Top RAM', current.topRamApp, Icons.memory_outlined, themeManager, isLoading),
                      _buildInfoTile('Disk Usage', '${current.disk.toStringAsFixed(1)}%', Icons.storage, themeManager, isLoading),
                      _buildInfoTile('Temp & Fan', '${current.temp.toStringAsFixed(1)}°C | ${current.fanSpeed.toInt()} RPM', Icons.thermostat, themeManager, isLoading),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => _showTop10Popup(context, themeManager, 'CPU'),
                    child: SizedBox(height: 200, child: _buildChartCard(context, 'CPU Usage', cpuSpots, Colors.cyanAccent, themeManager, isLoading)),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _showTop10Popup(context, themeManager, 'RAM'),
                    child: SizedBox(height: 200, child: _buildChartCard(context, 'RAM Usage', ramSpots, Colors.greenAccent, themeManager, isLoading)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildChartCard(context, 'GPU Usage', gpuSpots, Colors.purpleAccent, themeManager, isLoading)),
                ],
                const SizedBox(height: 24),
                const BatteryAnalytics(),
                const SizedBox(height: 32),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildOfflineState(ThemeManager themeManager) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(
          height: 400,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off_rounded, size: 64, color: themeManager.accentColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'PC OFFLINE',
                  style: TextStyle(
                    color: themeManager.textColor,
                    fontSize: 24,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '403/405 Connection Error\nAgent Unreachable',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: themeManager.textColor.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, ThemeManager theme, bool isLoading) {
    if (isLoading) {
      return RepaintBoundary(
        child: Shimmer.fromColors(
          baseColor: theme.textColor.withOpacity(0.1),
          highlightColor: theme.textColor.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              color: theme.chatBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.chatBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.textColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(color: theme.textColor.withOpacity(0.5), fontSize: 10, letterSpacing: 1),
                ),
                Text(
                  value,
                  style: TextStyle(color: theme.textColor, fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, String title, List<FlSpot> spots, Color lineColor, ThemeManager theme, bool isLoading) {
    return RepaintBoundary(
      child: Card(
        color: theme.chatBackgroundColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.textColor.withOpacity(0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                  ? Shimmer.fromColors(
                      baseColor: theme.textColor.withOpacity(0.1),
                      highlightColor: theme.textColor.withOpacity(0.2),
                      child: Container(color: Colors.white),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: theme.textColor.withOpacity(0.1),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%', style: TextStyle(color: theme.textColor.withOpacity(0.5), fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 60,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: lineColor,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: lineColor.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
