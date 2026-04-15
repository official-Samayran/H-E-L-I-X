import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:ui';
import '../services/telemetry_service.dart';
import '../theme/theme_manager.dart';

class SystemHud extends StatelessWidget {
  const SystemHud({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final telemetry = Provider.of<TelemetryService>(context);

    if (!telemetry.isWsConnected) {
      if (theme.currentThemeType == AppThemeType.oled) {
        return Container(
          height: 30,
          alignment: Alignment.center,
          child: Text(
            'SYSTEM STANDBY',
            style: TextStyle(
              color: theme.textColor.withOpacity(0.5),
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      }
      // Graceful Failure: Standby Blurred Mode
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.chatBackgroundColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.accentColor.withOpacity(0.1)),
            ),
            child: Center(
              child: Text(
                'SYSTEM STANDBY',
                style: TextStyle(
                  color: theme.textColor.withOpacity(0.5),
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final data = telemetry.currentData;

    if (theme.currentThemeType == AppThemeType.oled) {
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          'CPU: ${data.cpu.toInt()}%  |  RAM: ${data.ram.toInt()}%  |  GPU: ${data.gpu.toInt()}%  |  TEMP: ${data.temp.toInt()}°C',
          style: TextStyle(
            color: theme.textColor.withOpacity(0.7),
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.chatBackgroundColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.accentColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildGauge('CPU', data.cpu, theme),
          _buildGauge('RAM', data.ram, theme),
          _buildGauge('GPU', data.gpu, theme),
          _buildTextStat('TEMP', '${data.temp.toInt()}°C', theme),
        ],
      ),
    );
  }

  Widget _buildGauge(String label, double value, ThemeManager theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 20,
                  startDegreeOffset: 270,
                  sections: [
                    PieChartSectionData(
                      color: theme.accentColor,
                      value: value,
                      title: '',
                      radius: 8,
                    ),
                    PieChartSectionData(
                      color: theme.backgroundColor.withOpacity(0.5),
                      value: 100 - value,
                      title: '',
                      radius: 8,
                    ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    color: theme.textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.7),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextStat(String label, String value, ThemeManager theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.accentColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.textColor.withOpacity(0.7),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
