import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/enums/app_enums.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/providers/filter_provider.dart';
import '../../theme/app_dimens.dart';
import '../app_form_fields.dart';

abstract class FilterStrategy {
  List<Widget> buildFields(
    BuildContext context,
    FilterProvider provider,
    TextEditingController flowCtrl,
    TextEditingController headCtrl,
    TextEditingController cableCtrl,
    TextEditingController bombsCtrl, {
    required FocusNode flowFocus,
    required FocusNode headFocus,
    required FocusNode cableFocus,
    required FocusNode bombsFocus,
  });

  Widget buildCommonDropdowns(
    BuildContext context,
    FilterProvider provider,
    String categoryId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Selector<FilterProvider, String?>(
          selector: (_, p) => p.selectedApplication,
          builder: (context, selected, _) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: AppDropdown<String>(
                label: context.l10n.translate('applications'),
                hint: context.l10n.translate('pick_one'),
                value: selected,
                validator: (v) =>
                    v == null ? context.l10n.translate('required_field') : null,
                items: provider.applications
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['value'].toString(),
                        child: _buildText(context, e['title'].toString()),
                      ),
                    )
                    .toList(),
                onChanged: (val) => provider.setApplication(categoryId, val),
              ),
            );
          },
        ),
        Selector<FilterProvider, String?>(
          selector: (_, p) => p.selectedModel,
          builder: (context, selected, _) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: AppDropdown<String>(
                label: context.l10n.translate('models'),
                hint: context.l10n.translate('pick_one'),
                value: selected,
                validator: (v) =>
                    v == null ? context.l10n.translate('required_field') : null,
                items: provider.models
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['value'].toString(),
                        child: _buildText(context, e['title'].toString()),
                      ),
                    )
                    .toList(),
                onChanged: provider.setModel,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildFlowAndHead(
    BuildContext context,
    FilterProvider provider,
    TextEditingController flowCtrl,
    TextEditingController headCtrl, {
    required FocusNode flowFocus,
    required FocusNode headFocus,
    TextInputAction headAction = TextInputAction.done,
    VoidCallback? onHeadSubmitted,
  }) {
    return Column(
      children: [
        Selector<FilterProvider, String>(
          selector: (_, p) => p.selectedFlowUnit,
          builder: (context, unit, _) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: AppCompositeField(
                label: context.l10n.translate('flow'),
                controller: flowCtrl,
                focusNode: flowFocus,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => headFocus.requestFocus(),
                validator: (v) => v == null || v.isEmpty
                    ? context.l10n.translate('required_field')
                    : null,
                suffixWidget: DropdownButton<String>(
                  value: unit,
                  dropdownColor: context.theme.cardColor,
                  isDense: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: context.colors.primary,
                  ),
                  items: provider.flowUnits
                      .map(
                        (u) => DropdownMenuItem(
                          value: u['value'].toString(),
                          child: Text(
                            u['title'].toString(),
                            style: context.subtitleStyle?.copyWith(
                              fontSize: AppDimens.fontLg,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: provider.setFlowUnit,
                ),
              ),
            );
          },
        ),
        Selector<FilterProvider, String>(
          selector: (_, p) => p.selectedHeadUnit,
          builder: (context, unit, _) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.md),
              child: AppCompositeField(
                label: context.l10n.translate('manometric_head'),
                controller: headCtrl,
                focusNode: headFocus,
                textInputAction: headAction,
                onFieldSubmitted: (_) => onHeadSubmitted?.call(),
                validator: (v) => v == null || v.isEmpty
                    ? context.l10n.translate('required_field')
                    : null,
                suffixWidget: DropdownButton<String>(
                  value: unit,
                  dropdownColor: context.theme.cardColor,
                  isDense: true,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: context.colors.primary,
                  ),
                  items: provider.headUnits
                      .map(
                        (u) => DropdownMenuItem(
                          value: u['value'].toString(),
                          child: Text(
                            u['title'].toString(),
                            style: context.subtitleStyle?.copyWith(
                              fontSize: AppDimens.fontLg,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: provider.setHeadUnit,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildText(BuildContext context, String text) {
    return Text(
      text,
      style: context.subtitleStyle?.copyWith(fontSize: AppDimens.fontLg),
    );
  }
}

class StandardFilterStrategy extends FilterStrategy {
  final String categoryId;
  StandardFilterStrategy(this.categoryId);

  @override
  List<Widget> buildFields(
    BuildContext context,
    FilterProvider provider,
    TextEditingController flowCtrl,
    TextEditingController headCtrl,
    TextEditingController cableCtrl,
    TextEditingController bombsCtrl, {
    required FocusNode flowFocus,
    required FocusNode headFocus,
    required FocusNode cableFocus,
    required FocusNode bombsFocus,
  }) {
    final isSubmersible = categoryId == CategoryIds.submersible;

    return [
      buildCommonDropdowns(context, provider, categoryId),
      _FrequencySelector(),
      if (isSubmersible) _WellDiameterSelector(),
      buildFlowAndHead(
        context,
        provider,
        flowCtrl,
        headCtrl,
        flowFocus: flowFocus,
        headFocus: headFocus,
        headAction: TextInputAction.done,
      ),
    ];
  }
}

class SolarFilterStrategy extends FilterStrategy {
  @override
  List<Widget> buildFields(
    BuildContext context,
    FilterProvider provider,
    TextEditingController flowCtrl,
    TextEditingController headCtrl,
    TextEditingController cableCtrl,
    TextEditingController bombsCtrl, {
    required FocusNode flowFocus,
    required FocusNode headFocus,
    required FocusNode cableFocus,
    required FocusNode bombsFocus,
  }) {
    return [
      buildCommonDropdowns(context, provider, CategoryIds.solar),
      Selector<FilterProvider, String?>(
        selector: (_, p) => p.selectedSystemType,
        builder: (context, selected, _) {
          if (provider.systemTypes.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.md),
            child: AppDropdown<String>(
              label: context.l10n.translate('system_type'),
              hint: context.l10n.translate('pick_one'),
              value: selected,
              validator: (v) =>
                  v == null ? context.l10n.translate('required_field') : null,
              items: provider.systemTypes
                  .map(
                    (item) => DropdownMenuItem(
                      value: item['value'].toString(),
                      child: _buildText(
                        context,
                        context.l10n.translate(item['label']?.toString() ?? ''),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: provider.setSystemType,
            ),
          );
        },
      ),
      _WellDiameterSelector(),
      buildFlowAndHead(
        context,
        provider,
        flowCtrl,
        headCtrl,
        flowFocus: flowFocus,
        headFocus: headFocus,
        headAction: TextInputAction.next,
        onHeadSubmitted: () => cableFocus.requestFocus(),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.xl),
        child: AppTextField(
          label: context.l10n.translate('cable_length'),
          controller: cableCtrl,
          focusNode: cableFocus,
          textInputAction: TextInputAction.done,
        ),
      ),
    ];
  }
}

class PressurizerFilterStrategy extends FilterStrategy {
  @override
  List<Widget> buildFields(
    BuildContext context,
    FilterProvider provider,
    TextEditingController flowCtrl,
    TextEditingController headCtrl,
    TextEditingController cableCtrl,
    TextEditingController bombsCtrl, {
    required FocusNode flowFocus,
    required FocusNode headFocus,
    required FocusNode cableFocus,
    required FocusNode bombsFocus,
  }) {
    return [
      buildCommonDropdowns(context, provider, CategoryIds.pressurizer),
      buildFlowAndHead(
        context,
        provider,
        flowCtrl,
        headCtrl,
        flowFocus: flowFocus,
        headFocus: headFocus,
        headAction: provider.activationType == ActivationType.inversor.name
            ? TextInputAction.next
            : TextInputAction.done,
        onHeadSubmitted: () {
          if (provider.activationType == ActivationType.inversor.name) {
            bombsFocus.requestFocus();
          }
        },
      ),
      Selector<FilterProvider, String>(
        selector: (_, p) => p.activationType,
        builder: (context, activation, _) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.md),
            child: AppDropdown<String>(
              label: context.l10n.translate('activation_type'),
              hint: context.l10n.translate('pick_one'),
              value: activation,
              items:
                  [
                        ActivationType.pressostato.name,
                        ActivationType.inversor.name,
                      ]
                      .map(
                        (val) => DropdownMenuItem(
                          value: val,
                          child: _buildText(
                            context,
                            context.l10n.translate(
                              val == ActivationType.pressostato.name
                                  ? 'pressure_switch'
                                  : 'frequency_inverter',
                            ),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: provider.setActivationType,
            ),
          );
        },
      ),
      Selector<FilterProvider, String>(
        selector: (_, p) => p.activationType,
        builder: (context, activation, _) {
          if (activation != ActivationType.inversor.name) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimens.xl),
            child: AppTextField(
              label: context.l10n.translate('pumps_quantity'),
              controller: bombsCtrl,
              focusNode: bombsFocus,
              textInputAction: TextInputAction.done,
              isInteger: true,
              validator: (v) => v == null || v.isEmpty
                  ? context.l10n.translate('required_field')
                  : null,
            ),
          );
        },
      ),
    ];
  }
}

class _FrequencySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<FilterProvider>();
    return FormField<String>(
      initialValue: provider.selectedFrequency,
      validator: (val) {
        if (provider.selectedFrequency == null) {
          return context.l10n.translate('mandatory');
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.translate('frequency'),
                  style: context.subtitleStyle?.copyWith(
                    fontSize: AppDimens.fontLg,
                  ),
                ),
                if (state.hasError)
                  Text(
                    state.errorText!,
                    style: context.bodySmall?.copyWith(
                      color: context.colors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimens.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Selector<FilterProvider, String?>(
                selector: (_, p) => p.selectedFrequency,
                builder: (context, selected, _) {
                  final hasError = state.hasError;
                  final borderColor = hasError
                      ? context.colors.error
                      : context.colors.primary;

                  return Row(
                    children: provider.frequencies.map((f) {
                      final isSel = selected == f;
                      final colors = context.colors;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppDimens.sm),
                        child: InkWell(
                          onTap: () {
                            provider.setFrequency(f);
                            state.didChange(f);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimens.sm,
                              horizontal: AppDimens.xl,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? colors.primary
                                  : context.theme.cardColor,
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(
                                AppDimens.radiusSm,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "${f}Hz",
                                style: context.subtitleStyle?.copyWith(
                                  color: isSel
                                      ? colors.onPrimary
                                      : colors.primary,
                                  fontSize: AppDimens.fontLg,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDimens.lg),
          ],
        );
      },
    );
  }
}

class _WellDiameterSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.read<FilterProvider>();
    return Selector<FilterProvider, String?>(
      selector: (_, p) => p.selectedWellDiameter,
      builder: (context, selected, _) {
        if (provider.wellDiameters.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimens.md),
          child: AppDropdown<String>(
            label: context.l10n.translate('well_diameter'),
            hint: context.l10n.translate('pick_one'),
            value: selected,
            items: provider.wellDiameters
                .map(
                  (val) => DropdownMenuItem(
                    value: val,
                    child: Text(
                      val == SystemConstants.defaultValueZero
                          ? context.l10n.translate('all')
                          : val,
                      style: context.subtitleStyle?.copyWith(
                        fontSize: AppDimens.fontLg,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: provider.setWellDiameter,
          ),
        );
      },
    );
  }
}

class FilterStrategyFactory {
  static FilterStrategy create(String categoryId) {
    if (categoryId == CategoryIds.solar || categoryId == CategorySlugs.solar) {
      return SolarFilterStrategy();
    } else if (categoryId == CategoryIds.pressurizer ||
        categoryId == CategorySlugs.pressurizer) {
      return PressurizerFilterStrategy();
    } else {
      return StandardFilterStrategy(categoryId);
    }
  }
}
