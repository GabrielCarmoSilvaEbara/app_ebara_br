import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/ebara_data_service.dart';
import '../../core/providers/filter_provider.dart';
import 'app_buttons.dart';
import 'app_modal_wrapper.dart';
import 'app_skeletons.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';
import 'filters/filter_strategies.dart';
import '../../core/constants/app_constants.dart';

class FiltersBottomSheet extends StatefulWidget {
  final String categoryId;

  const FiltersBottomSheet({super.key, required this.categoryId});

  @override
  State<FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<FiltersBottomSheet> {
  final _flowController = TextEditingController();
  final _headController = TextEditingController();
  final _cableLengthController = TextEditingController();
  final _bombsQuantityController = TextEditingController(text: '1');
  late final FilterStrategy _strategy;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _strategy = FilterStrategyFactory.create(widget.categoryId);
  }

  @override
  void dispose() {
    _flowController.dispose();
    _headController.dispose();
    _cableLengthController.dispose();
    _bombsQuantityController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final provider = context.read<FilterProvider>();
    final result = provider.getFilterResult(
      flow: _flowController.text,
      head: _headController.text,
      cableLength: _cableLengthController.text,
      bombsQuantity: _bombsQuantityController.text,
    );

    if (result != null) {
      Navigator.of(context).pop(result);
    } else {
      setState(() => _showErrors = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FilterProvider(dataService: context.read<EbaraDataService>())
            ..loadFiltersData(widget.categoryId),
      child: Consumer<FilterProvider>(
        builder: (context, provider, _) {
          return AppModalWrapper(
            title: context.l10n.translate('filters'),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.lg,
                      vertical: AppDimens.sm,
                    ),
                    child: provider.isLoading
                        ? const FilterSkeleton()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _strategy.buildFields(
                              context,
                              provider,
                              _flowController,
                              _headController,
                              _cableLengthController,
                              _bombsQuantityController,
                              showErrors: _showErrors,
                            ),
                          ),
                  ),
                ),
                if (!provider.isLoading)
                  _ActionArea(
                    onPressed: () => _submit(context),
                    controllers: [
                      _flowController,
                      _headController,
                      if (widget.categoryId == CategoryIds.solar)
                        _cableLengthController,
                      _bombsQuantityController,
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  final VoidCallback onPressed;
  final List<Listenable> controllers;

  const _ActionArea({required this.onPressed, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.lg,
        AppDimens.zero,
        AppDimens.lg,
        AppDimens.lg,
      ),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        boxShadow: AppShadows.sm(context.colors.shadow),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: AppDimens.md),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: AnimatedBuilder(
              animation: Listenable.merge(controllers),
              builder: (context, child) {
                return AppPrimaryButton(
                  onPressed: onPressed,
                  text: context.l10n.translate('search'),
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.onPrimary,
                  height: 50,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
