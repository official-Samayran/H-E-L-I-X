import 'package:flutter/material.dart';

class AnimatedAura extends StatefulWidget {
  final Color color;

  const AnimatedAura({super.key, required this.color});

  @override
  State<AnimatedAura> createState() => _AnimatedAuraState();
}

class _AnimatedAuraState extends State<AnimatedAura>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TweenAnimationBuilder allows the color to transition smoothly when theme changes
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: widget.color, end: widget.color),
      duration: const Duration(milliseconds: 600),
      builder: (context, color, child) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final activeColor = color ?? widget.color;
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(_opacityAnimation.value),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                    BoxShadow(
                      color: activeColor.withOpacity(_opacityAnimation.value * 0.5),
                      blurRadius: 150,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
