import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';
import 'filters_bottom_sheet.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final String selectedCategoryId;
  final Function(Map<String, dynamic>)? onFiltersApplied;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hintText = 'Search...',
    required this.selectedCategoryId,
    this.onFiltersApplied,
    this.onChanged,
    this.controller,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  Future<void> _openFilters() async {
    final result = await context.showAppBottomSheet<Map<String, dynamic>>(
      child: FiltersBottomSheet(categoryId: widget.selectedCategoryId),
    );

    if (result != null && widget.onFiltersApplied != null) {
      widget.onFiltersApplied!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: _buildContainerDecoration(context),
      child: Row(
        children: [
          Expanded(child: _buildTextField(context)),
          _buildFilterButton(context),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      boxShadow: AppShadows.sm(context.colors.shadow),
    );
  }

  Widget _buildTextField(BuildContext context) {
    final colors = context.colors;

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      textAlignVertical: TextAlignVertical.center,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: context.bodySmall,
        prefixIcon: Icon(Icons.search, color: colors.onSurface),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(Icons.clear, color: colors.onSurface),
                onPressed: _clearSearch,
                splashRadius: 20,
              )
            : null,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.primary,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: InkWell(
        onTap: _openFilters,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(Icons.tune, color: colors.onPrimary),
        ),
      ),
    );
  }
}
