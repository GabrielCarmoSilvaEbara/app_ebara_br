import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;

  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (_, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final shimmerPosition = _controller.value * 2 - 1;

            return LinearGradient(
              begin: Alignment(-1 + shimmerPosition, -1),
              end: Alignment(1 + shimmerPosition, 1),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
  }
}
