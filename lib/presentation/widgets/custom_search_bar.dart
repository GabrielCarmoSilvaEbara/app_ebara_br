import 'package:flutter/material.dart';
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
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          FiltersBottomSheet(categoryId: widget.selectedCategoryId),
    );

    if (result != null && widget.onFiltersApplied != null) {
      widget.onFiltersApplied!(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 56,
      decoration: _buildContainerDecoration(colorScheme),
      child: Row(
        children: [
          Expanded(child: _buildTextField(colorScheme)),
          _buildFilterButton(colorScheme),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration(ColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          spreadRadius: 1,
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildTextField(ColorScheme colorScheme) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(Icons.search, color: colorScheme.onSurface),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(Icons.clear, color: colorScheme.onSurface),
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

  Widget _buildFilterButton(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.primary,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _openFilters,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(Icons.tune, color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
