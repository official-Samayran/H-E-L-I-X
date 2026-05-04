import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/theme_manager.dart';
import '../../services/telemetry_service.dart';
import '../../services/connection_service.dart';

class SystemDashboardTab extends StatelessWidget {
  const SystemDashboardTab({super.key});

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
                Text(
                  'SYSTEM TELEMETRY',
                  style: TextStyle(
                    color: themeManager.textColor,
                    fontSize: 18,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Top Apps & Info Grid
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
                SizedBox(height: 200, child: _buildChartCard(context, 'CPU Usage', cpuSpots, Colors.cyanAccent, themeManager, isLoading)),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildChartCard(context, 'RAM Usage', ramSpots, Colors.greenAccent, themeManager, isLoading)),
                const SizedBox(height: 16),
                SizedBox(height: 200, child: _buildChartCard(context, 'GPU Usage', gpuSpots, Colors.purpleAccent, themeManager, isLoading)),
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
