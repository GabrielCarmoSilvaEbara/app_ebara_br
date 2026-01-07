import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_dimens.dart';
import '../../theme/app_shadows.dart';
import '../../../core/extensions/context_extensions.dart';

class AnimatedGauge extends StatelessWidget {
  final double value;
  final double max;
  final String label;
  final String unit;
  final Color? color;

  const AnimatedGauge({
    super.key,
    required this.value,
    this.max = 100,
    required this.label,
    required this.unit,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (value / max).clamp(0.0, 1.0);
    final effectiveColor = color ?? context.colors.primary;

    return Container(
      padding: const EdgeInsets.all(AppDimens.lg),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        boxShadow: AppShadows.sm(context.colors.shadow),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: context.subtitleStyle?.copyWith(
              fontSize: AppDimens.fontLg,
              color: context.colors.onSurface.withValues(
                alpha: AppDimens.opacityHigh,
              ),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: AppDimens.gaugeSize,
            width: AppDimens.gaugeSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: 1.0,
                  color: context.colors.onSurface.withValues(
                    alpha: AppDimens.opacityLow,
                  ),
                  strokeWidth: AppDimens.gaugeStroke,
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: percentage),
                  duration: AppDimens.durationGauge,
                  curve: Curves.easeOutCubic,
                  builder: (context, val, _) {
                    return CircularProgressIndicator(
                      value: val,
                      color: effectiveColor,
                      strokeWidth: AppDimens.gaugeStroke,
                      strokeCap: StrokeCap.round,
                    );
                  },
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value.toStringAsFixed(2),
                        style: context.titleStyle?.copyWith(
                          fontSize: AppDimens.fontDisplay,
                          color: effectiveColor,
                        ),
                      ),
                      Text(unit, style: context.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedCopyButton extends StatefulWidget {
  final String textToCopy;
  final Widget child;

  const AnimatedCopyButton({
    super.key,
    required this.textToCopy,
    required this.child,
  });

  @override
  State<AnimatedCopyButton> createState() => _AnimatedCopyButtonState();
}

class _AnimatedCopyButtonState extends State<AnimatedCopyButton> {
  bool _isCopied = false;

  void _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.textToCopy));
    if (mounted) {
      setState(() => _isCopied = true);
      HapticFeedback.mediumImpact();

      Future.delayed(AppDimens.durationCopy, () {
        if (mounted) setState(() => _isCopied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: AppDimens.durationFast,
            opacity: _isCopied ? 0.0 : 1.0,
            child: widget.child,
          ),
          AnimatedOpacity(
            duration: AppDimens.durationFast,
            opacity: _isCopied ? 1.0 : 0.0,
            child: Container(
              padding: const EdgeInsets.all(AppDimens.xs),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: AppDimens.opacityMed),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: AppDimens.iconXl,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
