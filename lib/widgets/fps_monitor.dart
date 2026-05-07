import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';

class FpsMonitor extends StatefulWidget {
  final Widget child;

  const FpsMonitor({super.key, required this.child});

  @override
  State<FpsMonitor> createState() => _FpsMonitorState();
}

class _FpsMonitorState extends State<FpsMonitor> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _previousTime = Duration.zero;
  double _fps = 0.0;
  final int _fpsAverageCount = 60;
  final List<double> _fpsHistory = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    if (_previousTime == Duration.zero) {
      _previousTime = elapsed;
      return;
    }

    final delta = (elapsed - _previousTime).inMicroseconds;
    _previousTime = elapsed;

    if (delta > 0) {
      final currentFps = 1000000 / delta;
      
      _fpsHistory.add(currentFps);
      if (_fpsHistory.length > _fpsAverageCount) {
        _fpsHistory.removeAt(0);
      }

      final double avgFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;

      if ((_fps - avgFps).abs() > 1.0) {
        setState(() {
          _fps = avgFps;
        });
      } else if (mounted) {
        final theme = Provider.of<ThemeManager>(context, listen: false);
        if (theme.fpsSyncLock) {
          setState(() {}); // Force continuous rebuild loop
        }
      }
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 32,
          right: 16,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${_fps.toStringAsFixed(1)} FPS',
                style: GoogleFonts.spaceMono(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
