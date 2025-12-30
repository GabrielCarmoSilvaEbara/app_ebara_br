import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class AppFormLabel extends StatelessWidget {
  final String label;
  const AppFormLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? theme.cardColor : Colors.white,
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
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                    hintText: hintText ?? '0,0',
                    hintStyle: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              if (suffixText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  child: Text(
                    suffixText!,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: Colors.grey,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) AppFormLabel(label!),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? theme.cardColor : Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: value,
              dropdownColor: theme.cardColor,
              icon: const Icon(Icons.unfold_more, color: AppColors.primary),
              hint: hint != null
                  ? Text(
                      hint!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    )
                  : null,
              items: items,
              onChanged: onChanged,
              style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormLabel(label),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(8),
            color: isDark ? theme.cardColor : Colors.white,
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
                  style: theme.textTheme.displayMedium?.copyWith(fontSize: 14),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    border: InputBorder.none,
                    hintText: '0,0',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: unitValue,
                    dropdownColor: theme.cardColor,
                    isDense: true,
                    items: unitItems
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['value'].toString(),
                            child: Text(
                              u['title'].toString(),
                              style: theme.textTheme.displayMedium?.copyWith(
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
