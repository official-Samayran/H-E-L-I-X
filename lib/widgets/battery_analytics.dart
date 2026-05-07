import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
import '../services/connection_service.dart';

class BatteryAnalyticsItem {
  final String name;
  final double load;
  BatteryAnalyticsItem(this.name, this.load);
}

class BatteryAnalytics extends StatelessWidget {
  const BatteryAnalytics({super.key});

  List<BatteryAnalyticsItem> _computeLoads(ThemeManager theme, ConnectionService connection) {
    List<BatteryAnalyticsItem> loads = [
      BatteryAnalyticsItem("Base System Core", 1.0),
      BatteryAnalyticsItem("Telemetry Polling", 1.2),
    ];
    
    if (theme.fpsSyncLock) {
      loads.add(BatteryAnalyticsItem("144Hz Sync Lock", 4.5));
    }
    
    if (connection.isTyping) {
      loads.add(BatteryAnalyticsItem("Neural NLP Engine", 6.0));
    }
    
    // Mock secure screen tracking based on oled theme for demonstration
    if (theme.currentThemeType == AppThemeType.oled) {
      loads.add(BatteryAnalyticsItem("OLED Deep Black", -0.8));
    }
    
    return loads;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    final connection = Provider.of<ConnectionService>(context);
    
    final loads = _computeLoads(theme, connection);
    final totalLoad = loads.fold(0.0, (sum, item) => sum + item.load);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BATTERY IMPACT LOG',
                style: TextStyle(
                  color: theme.textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'TOTAL: ${totalLoad.toStringAsFixed(1)}% / hr',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: theme.textColor.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          ...loads.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: theme.textColor.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  '${item.load > 0 ? '+' : ''}${item.load.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: item.load > 0 ? theme.textColor : Colors.greenAccent,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
