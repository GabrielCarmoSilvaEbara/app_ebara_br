import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';

class AppFormLabel extends StatelessWidget {
  final String label;
  const AppFormLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.xs),
      child: Text(
        label,
        style: context.subtitleStyle?.copyWith(fontSize: AppDimens.fontLg),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? suffixText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool isInteger;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.suffixText,
    this.hintText,
    this.onChanged,
    this.isInteger = false,
    this.textInputAction = TextInputAction.done,
    this.keyboardType,
    this.focusNode,
    this.onFieldSubmitted,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderSide = BorderSide(color: colors.primary, width: 2);
    final errorBorderSide = BorderSide(color: colors.error, width: 2);
    final radius = BorderRadius.circular(AppDimens.radiusSm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType:
              keyboardType ??
              TextInputType.numberWithOptions(decimal: !isInteger),
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          inputFormatters: [
            if (isInteger)
              FilteringTextInputFormatter.digitsOnly
            else
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
          ],
          onChanged: onChanged,
          style: context.subtitleStyle?.copyWith(fontSize: AppDimens.fontXl),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: AppDimens.sm,
            ),
            hintText: hintText ?? '0,0',
            hintStyle: context.bodySmall,
            suffixText: suffixText,
            suffixStyle: context.subtitleStyle?.copyWith(
              color: colors.onSurface.withValues(alpha: AppDimens.opacityHigh),
              fontSize: AppDimens.fontLg,
            ),
            border: OutlineInputBorder(
              borderSide: borderSide,
              borderRadius: radius,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: borderSide,
              borderRadius: radius,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: borderSide,
              borderRadius: radius,
            ),
            errorBorder: OutlineInputBorder(
              borderSide: errorBorderSide,
              borderRadius: radius,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: errorBorderSide,
              borderRadius: radius,
            ),
          ),
        ),
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final String? Function(T?)? validator;

  const AppDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderSide = BorderSide(color: colors.primary, width: 2);
    final errorBorderSide = BorderSide(color: colors.error, width: 2);
    final radius = BorderRadius.circular(AppDimens.radiusSm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: onChanged,
          validator: validator,
          dropdownColor: context.theme.cardColor,
          icon: Icon(Icons.unfold_more, color: colors.primary),
          hint: hint != null ? Text(hint!, style: context.bodySmall) : null,
          style: context.subtitleStyle?.copyWith(fontSize: AppDimens.fontLg),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimens.md,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderSide: borderSide,
              borderRadius: radius,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: borderSide,
              borderRadius: radius,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: borderSide,
              borderRadius: radius,
            ),
            errorBorder: OutlineInputBorder(
              borderSide: errorBorderSide,
              borderRadius: radius,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: errorBorderSide,
              borderRadius: radius,
            ),
          ),
        ),
      ],
    );
  }
}

class AppCompositeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Widget suffixWidget;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const AppCompositeField({
    super.key,
    required this.label,
    required this.controller,
    required this.suffixWidget,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.formatters,
    this.focusNode,
    this.onFieldSubmitted,
    this.textInputAction,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderSide = BorderSide(color: colors.primary, width: 2);
    final errorBorderSide = BorderSide(color: colors.error, width: 2);
    final radius = BorderRadius.circular(AppDimens.radiusSm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormLabel(label),
        FormField<String>(
          validator: validator,
          initialValue: controller.text,
          builder: (FormFieldState<String> state) {
            final hasError = state.hasError;
            final effectiveBorderSide = hasError ? errorBorderSide : borderSide;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: effectiveBorderSide.color,
                      width: effectiveBorderSide.width,
                    ),
                    borderRadius: radius,
                    color: context.theme.cardColor,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          keyboardType: keyboardType,
                          textInputAction:
                              textInputAction ?? TextInputAction.next,
                          onFieldSubmitted: onFieldSubmitted,
                          onChanged: (val) {
                            state.didChange(val);
                          },
                          inputFormatters:
                              formatters ??
                              [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*[.,]?\d*'),
                                ),
                              ],
                          style: context.subtitleStyle?.copyWith(
                            fontSize: AppDimens.fontLg,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: AppDimens.md,
                            ),
                            border: InputBorder.none,
                            hintText: '0,0',
                          ),
                        ),
                      ),
                      _SuffixContainer(
                        borderColor: effectiveBorderSide.color,
                        child: suffixWidget,
                      ),
                    ],
                  ),
                ),
                if (hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(
                      state.errorText!,
                      style: context.bodySmall?.copyWith(
                        color: colors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SuffixContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _SuffixContainer({required this.child, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.sm),
      height: 48,
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: borderColor, width: 2)),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(child: child),
    );
  }
}
