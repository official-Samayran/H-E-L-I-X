import 'package:flutter/material.dart';

class AdaptiveUI extends InheritedWidget {
  final double scale;

  const AdaptiveUI({
    super.key,
    required this.scale,
    required super.child,
  });

  static AdaptiveUI? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AdaptiveUI>();
  }

  @override
  bool updateShouldNotify(AdaptiveUI oldWidget) {
    return scale != oldWidget.scale;
  }
}

extension ScaleExt on num {
  double s(BuildContext context) {
    final adaptive = AdaptiveUI.of(context);
    final scale = adaptive?.scale ?? 1.0;
    return this * scale;
  }
}
