import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import 'app_form_fields.dart';

class InteractiveSliderInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String suffix;
  final double min;
  final double max;
  final VoidCallback onChanged;

  const InteractiveSliderInput({
    super.key,
    required this.label,
    required this.controller,
    required this.suffix,
    this.min = 0,
    this.max = 100,
    required this.onChanged,
  });

  @override
  State<InteractiveSliderInput> createState() => _InteractiveSliderInputState();
}

class _InteractiveSliderInputState extends State<InteractiveSliderInput> {
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = double.tryParse(widget.controller.text) ?? 0;
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onTextChange() {
    final val =
        double.tryParse(widget.controller.text.replaceAll(',', '.')) ?? 0;
    if (val != _currentValue) {
      setState(() {
        _currentValue = val.clamp(widget.min, widget.max);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: context.subtitleStyle?.copyWith(
                fontSize: AppDimens.fontLg,
              ),
            ),
            Text(
              "${_currentValue.toStringAsFixed(1)} ${widget.suffix}",
              style: context.bodyStyle?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colors.primary,
            inactiveTrackColor: colors.primary.withValues(
              alpha: AppDimens.opacityLow,
            ),
            thumbColor: colors.primary,
            overlayColor: colors.primary.withValues(
              alpha: AppDimens.opacityLow,
            ),
            trackHeight: AppDimens.xxs,
          ),
          child: Slider(
            value: _currentValue,
            min: widget.min,
            max: widget.max,
            onChanged: (val) {
              setState(() => _currentValue = val);
              widget.controller.text = val.toStringAsFixed(1);
              widget.onChanged();
            },
          ),
        ),
        AppTextField(
          controller: widget.controller,
          suffixText: widget.suffix,
          onChanged: (_) => widget.onChanged(),
        ),
      ],
    );
  }
}
