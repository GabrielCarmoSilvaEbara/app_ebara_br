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
    bool showErrors = false,
  });

  Widget buildCommonDropdowns(
    BuildContext context,
    FilterProvider provider,
    String categoryId, {
    bool showErrors = false,
  }) {
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
                errorText: showErrors && selected == null
                    ? context.l10n.translate('required_field')
                    : null,
                items: provider.applications
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: _buildText(context, e),
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
                errorText: showErrors && selected == null
                    ? context.l10n.translate('required_field')
                    : null,
                items: provider.models
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: _buildText(context, e),
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
    bool showErrors = false,
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
                errorText: showErrors && flowCtrl.text.isEmpty
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
                errorText: showErrors && headCtrl.text.isEmpty
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
    bool showErrors = false,
  }) {
    final isSubmersible = categoryId == CategoryIds.submersible;

    return [
      buildCommonDropdowns(
        context,
        provider,
        categoryId,
        showErrors: showErrors,
      ),
      _FrequencySelector(showErrors: showErrors),
      if (isSubmersible) _WellDiameterSelector(),
      buildFlowAndHead(
        context,
        provider,
        flowCtrl,
        headCtrl,
        showErrors: showErrors,
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
    bool showErrors = false,
  }) {
    return [
      buildCommonDropdowns(
        context,
        provider,
        CategoryIds.solar,
        showErrors: showErrors,
      ),
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
              errorText: showErrors && selected == null
                  ? context.l10n.translate('required_field')
                  : null,
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
        showErrors: showErrors,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: AppDimens.xl),
        child: AppTextField(
          label: context.l10n.translate('cable_length'),
          controller: cableCtrl,
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
    bool showErrors = false,
  }) {
    return [
      buildCommonDropdowns(
        context,
        provider,
        CategoryIds.pressurizer,
        showErrors: showErrors,
      ),
      buildFlowAndHead(
        context,
        provider,
        flowCtrl,
        headCtrl,
        showErrors: showErrors,
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
              isInteger: true,
              errorText: showErrors && bombsCtrl.text.isEmpty
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
  final bool showErrors;
  const _FrequencySelector({this.showErrors = false});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<FilterProvider>();
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
            if (showErrors && provider.selectedFrequency == null)
              Text(
                context.l10n.translate('mandatory'),
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
              final hasError = showErrors && selected == null;
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
                      onTap: () => provider.setFrequency(f),
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
                              color: isSel ? colors.onPrimary : colors.primary,
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
                      val == '0' ? context.l10n.translate('all') : val,
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
    if (categoryId == CategoryIds.solar) {
      return SolarFilterStrategy();
    } else if (categoryId == CategoryIds.pressurizer ||
        categoryId == CategoryIds.pressurizerSlug) {
      return PressurizerFilterStrategy();
    } else {
      return StandardFilterStrategy(categoryId);
    }
  }
}
