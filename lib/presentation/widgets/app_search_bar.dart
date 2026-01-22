import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final VoidCallback? onClear;
  final Duration? debounceDuration;
  final bool showFilterButton;
  final bool enabled;
  final bool autoFocus;

  final List<String> searchHistory;
  final ValueChanged<String>? onHistorySelect;
  final ValueChanged<String>? onHistoryRemove;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.onClear,
    this.debounceDuration,
    this.showFilterButton = true,
    this.enabled = true,
    this.autoFocus = false,
    this.searchHistory = const [],
    this.onHistorySelect,
    this.onHistoryRemove,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    if (widget.debounceDuration == null) {
      widget.onChanged?.call(value);
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(widget.debounceDuration!, () {
      widget.onChanged?.call(value);
    });
  }

  void _onSuggestionSelected(String suggestion) {
    _controller.text = suggestion;
    _handleChanged(suggestion);
    _focusNode.unfocus();
    widget.onHistorySelect?.call(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        return RawAutocomplete<String>(
          focusNode: _focusNode,
          textEditingController: _controller,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isNotEmpty) {
              return const Iterable<String>.empty();
            }
            return widget.searchHistory;
          },
          onSelected: _onSuggestionSelected,
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                return Container(
                  height: AppDimens.inputHeight,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    boxShadow: AppShadows.sm(colors.shadow),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          focusNode: focusNode,
                          enabled: widget.enabled,
                          autofocus: widget.autoFocus,
                          textAlignVertical: TextAlignVertical.center,
                          onChanged: _handleChanged,
                          onSubmitted: (val) {
                            widget.onSubmitted?.call(val);
                          },
                          style: TextStyle(color: colors.onSurface),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: context.bodySmall,
                            prefixIcon: Icon(
                              Icons.search,
                              color: colors.onSurface.withValues(
                                alpha: AppDimens.opacityDisabled,
                              ),
                            ),
                            suffixIcon:
                                ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: textController,
                                  builder: (context, value, _) {
                                    if (value.text.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: colors.onSurface,
                                      ),
                                      onPressed: () {
                                        textController.clear();
                                        widget.onClear?.call();
                                        widget.onChanged?.call('');
                                      },
                                      splashRadius: AppDimens.radiusXl,
                                    );
                                  },
                                ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.sm,
                            ),
                          ),
                        ),
                      ),
                      if (widget.showFilterButton && widget.onFilterTap != null)
                        _FilterButton(onTap: widget.onFilterTap!),
                    ],
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppDimens.radiusMd),
                ),
                color: colors.surface,
                child: Container(
                  width: constraints.maxWidth,
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.history, size: 20),
                        title: Text(option),
                        onTap: () => onSelected(option),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => widget.onHistoryRemove?.call(option),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          width: AppDimens.inputHeight,
          height: AppDimens.inputHeight,
          alignment: Alignment.center,
          child: Icon(Icons.tune, color: colors.onPrimary),
        ),
      ),
    );
  }
}
