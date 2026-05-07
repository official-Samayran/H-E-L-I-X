import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';

class SprintLogScreen extends StatefulWidget {
  const SprintLogScreen({super.key});

  @override
  State<SprintLogScreen> createState() => _SprintLogScreenState();
}

class _SprintLogScreenState extends State<SprintLogScreen> {
  final List<Map<String, String>> sprints = [
    {'sprint': 'Sprint 1.0', 'title': 'Core Genesis', 'desc': 'Initialization of Helix engine, basic offline caching.'},
    {'sprint': 'Sprint 2.5', 'title': 'Neural Link', 'desc': 'Integration with Gemini API and Ollama local fallback.'},
    {'sprint': 'Sprint 3.2', 'title': 'Telemetry Hub', 'desc': 'Hardware resource monitoring, real-time metrics UI.'},
    {'sprint': 'Sprint 4.0', 'title': 'Aesthetic Override', 'desc': 'Glassmorphism, Neon Edge lighting, Particle backgrounds.'},
    {'sprint': 'Sprint 5.5', 'title': 'Secure Protocols', 'desc': 'FLAG_SECURE implementation, local auth, safe-wipe.'},
    {'sprint': 'Sprint 6.1', 'title': 'Context Engine', 'desc': 'Smart reply chips, offline context syncer.'},
    {'sprint': 'Sprint 7.10', 'title': 'Cybernetic Polish', 'desc': 'Gesture Tab Peek, 144 FPS Lock, ASCII terminal mode.'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeManager>(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'HISTORY OF HELIX',
          style: TextStyle(color: theme.textColor, letterSpacing: 4, fontWeight: FontWeight.w300, fontSize: 16),
        ),
        iconTheme: IconThemeData(color: theme.accentColor),
      ),
      body: ListView.builder(
        itemCount: sprints.length,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        itemBuilder: (context, index) {
          return _TimelineNode(
            index: index,
            sprint: sprints[index],
            isLast: index == sprints.length - 1,
          );
        },
      ),
    );
  }
}

class _TimelineNode extends StatefulWidget {
  final int index;
  final Map<String, String> sprint;
  final bool isLast;

  const _TimelineNode({required this.index, required this.sprint, required this.isLast});

  @override
  State<_TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<_TimelineNode> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) _controller.forward();
    });
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
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: SlideTransition(
            position: _slide,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: theme.accentColor.withValues(alpha: 0.8), blurRadius: 16, spreadRadius: 4),
                          ],
                        ),
                      ),
                      if (!widget.isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: theme.accentColor.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.sprint['sprint']!,
                            style: TextStyle(
                              color: theme.accentColor,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.chatBackgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.accentColor.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))
                              ]
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.sprint['title']!,
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.sprint['desc']!,
                                  style: TextStyle(
                                    color: theme.textColor.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
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
      },
    );
  }
}
