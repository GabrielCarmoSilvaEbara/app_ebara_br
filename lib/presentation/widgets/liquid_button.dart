import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';

class LiquidLoadingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;
  final double height;
  final double width;

  const LiquidLoadingButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    required this.child,
    this.height = 55,
    this.width = double.infinity,
  });

  @override
  State<LiquidLoadingButton> createState() => _LiquidLoadingButtonState();
}

class _LiquidLoadingButtonState extends State<LiquidLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant LiquidLoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            SizedBox.expand(
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  disabledBackgroundColor: colors.primary.withValues(
                    alpha: 0.5,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: widget.isLoading ? const SizedBox() : widget.child,
              ),
            ),
            if (widget.isLoading)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _WaterWavePainter(
                        animationValue: _controller.value,
                        color: colors.onPrimary.withValues(alpha: 0.3),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaterWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _WaterWavePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    const waveHeight = 10.0;
    final offset = size.width * animationValue;

    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.4);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        (size.height * 0.4) +
            math.sin((i + offset) * 2 * math.pi / (size.width * 0.8)) *
                waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
