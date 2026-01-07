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

class _InputContainer extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color backgroundColor;

  const _InputContainer({
    required this.child,
    required this.borderColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        color: backgroundColor,
      ),
      child: child,
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        text,
        style: context.bodySmall?.copyWith(
          color: context.colors.error,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
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
  final String? errorText;

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
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError ? colors.error : colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            color: context.theme.cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType:
                      keyboardType ??
                      TextInputType.numberWithOptions(decimal: !isInteger),
                  textInputAction: textInputAction,
                  inputFormatters: [
                    if (isInteger)
                      FilteringTextInputFormatter.digitsOnly
                    else
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d*'),
                      ),
                  ],
                  onChanged: onChanged,
                  style: context.subtitleStyle?.copyWith(
                    fontSize: AppDimens.fontXl,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.md,
                      vertical: AppDimens.sm,
                    ),
                    border: InputBorder.none,
                    hintText: hintText ?? '0,0',
                    hintStyle: context.bodySmall,
                  ),
                ),
              ),
              if (suffixText != null)
                _SuffixContainer(
                  borderColor: borderColor,
                  child: Text(
                    suffixText!,
                    style: context.subtitleStyle?.copyWith(
                      color: colors.onSurface.withValues(
                        alpha: AppDimens.opacityHigh,
                      ),
                      fontSize: AppDimens.fontLg,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasError) _ErrorText(errorText!),
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
  final String? errorText;

  const AppDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError
        ? context.colors.error
        : context.colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        _InputContainer(
          borderColor: borderColor,
          backgroundColor: context.theme.cardColor,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              dropdownColor: context.theme.cardColor,
              icon: Icon(Icons.unfold_more, color: context.colors.primary),
              hint: hint != null ? Text(hint!, style: context.bodySmall) : null,
              items: items,
              onChanged: onChanged,
              style: context.subtitleStyle?.copyWith(
                fontSize: AppDimens.fontLg,
              ),
            ),
          ),
        ),
        if (hasError) _ErrorText(errorText!),
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
  final String? errorText;

  const AppCompositeField({
    super.key,
    required this.label,
    required this.controller,
    required this.suffixWidget,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.formatters,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = errorText != null && errorText!.isNotEmpty;
    final borderColor = hasError ? colors.error : colors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormLabel(label),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            color: context.theme.cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textInputAction: TextInputAction.next,
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
              _SuffixContainer(borderColor: borderColor, child: suffixWidget),
            ],
          ),
        ),
        if (hasError) _ErrorText(errorText!),
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
