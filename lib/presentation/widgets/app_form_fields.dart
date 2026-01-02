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
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: context.subtitleStyle?.copyWith(fontSize: 14)),
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

  const AppTextField({
    super.key,
    required this.controller,
    this.label,
    this.suffixText,
    this.hintText,
    this.onChanged,
    this.isInteger = false,
    this.textInputAction = TextInputAction.done,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            color: context.theme.cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: !isInteger,
                  ),
                  textInputAction: textInputAction,
                  inputFormatters: [
                    isInteger
                        ? FilteringTextInputFormatter.digitsOnly
                        : FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                  ],
                  onChanged: onChanged,
                  style: context.subtitleStyle?.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.md,
                    ),
                    border: InputBorder.none,
                    hintText: hintText ?? '0,0',
                    hintStyle: context.bodySmall,
                  ),
                ),
              ),
              if (suffixText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.md,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: colors.primary, width: 2),
                    ),
                  ),
                  child: Text(
                    suffixText!,
                    style: context.subtitleStyle?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
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

  const AppDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.md),
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            color: context.theme.cardColor,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              dropdownColor: context.theme.cardColor,
              icon: Icon(Icons.unfold_more, color: colors.primary),
              hint: hint != null ? Text(hint!, style: context.bodySmall) : null,
              items: items,
              onChanged: onChanged,
              style: context.subtitleStyle?.copyWith(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class AppNumericDropdown extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unitValue;
  final List<Map<String, dynamic>> unitItems;
  final ValueChanged<String?> onUnitChanged;

  const AppNumericDropdown({
    super.key,
    required this.label,
    required this.controller,
    required this.unitValue,
    required this.unitItems,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormLabel(label),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colors.primary, width: 2),
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            color: context.theme.cardColor,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
                  ],
                  style: context.subtitleStyle?.copyWith(fontSize: 14),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppDimens.md,
                    ),
                    border: InputBorder.none,
                    hintText: '0,0',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unitValue,
                    dropdownColor: context.theme.cardColor,
                    isDense: true,
                    items: unitItems
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['value'].toString(),
                            child: Text(
                              u['title'].toString(),
                              style: context.subtitleStyle?.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: onUnitChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
