import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/location_service.dart';
import '../services/translation_service.dart';

class LocationSelectorSheet extends StatefulWidget {
  final Function(String city, String state, String country) onSelected;

  const LocationSelectorSheet({super.key, required this.onSelected});

  @override
  State<LocationSelectorSheet> createState() => LocationSelectorSheetState();
}

class LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _recent = <Map<String, String>>[];

  var _loading = false;
  String? _error;
  var _cities = <Map<String, String>>[];

  static const _minQueryLength = 3;
  static const _maxRecentItems = 5;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.length < _minQueryLength) {
      setState(
        () => _error = TranslationService.translate('error_min_letters'),
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await LocationService.searchCities(query: query);
      if (mounted) {
        setState(() => _cities = result);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = TranslationService.translate('error_fetching_cities'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectCity(Map<String, String> city) {
    _addToRecent(city);
    widget.onSelected(city['city']!, city['state']!, city['country']!);
    Navigator.of(context).pop();
  }

  void _addToRecent(Map<String, String> city) {
    _recent.removeWhere(
      (e) => e['city'] == city['city'] && e['state'] == city['state'],
    );
    _recent.insert(0, city);

    if (_recent.length > _maxRecentItems) {
      _recent.removeLast();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final topPadding = mediaQuery.padding.top;
    final isKeyboardVisible = keyboardHeight > 0;

    final availableHeight = screenHeight - topPadding - keyboardHeight;
    final sheetHeight = isKeyboardVisible
        ? availableHeight - 40
        : screenHeight * 0.6;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: sheetHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHandle(),
            _buildHeader(),
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                children: [
                  _buildSearchField(),
                  if (_error != null) _buildError(),
                  const SizedBox(height: 16),
                  _buildSearchButton(),
                  const SizedBox(height: 24),
                  _buildContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            TranslationService.translate('select_location'),
            style: AppTextStyles.text.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _search(),
      onChanged: (_) {
        if (_error != null) {
          setState(() => _error = null);
        }
      },
      decoration: InputDecoration(
        hintText: TranslationService.translate('enter_city_name'),
        hintStyle: AppTextStyles.text4,
        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _controller.clear();
                  setState(() {
                    _cities = [];
                    _error = null;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: AppTextStyles.text4.copyWith(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _search,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.primary.withOpacity(0.3),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    TranslationService.translate('search_button'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildContent() {
    if (_cities.isNotEmpty) {
      return _buildCityList();
    }

    if (_recent.isNotEmpty && !_loading) {
      return _buildRecent();
    }

    return const SizedBox.shrink();
  }

  Widget _buildCityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            TranslationService.translate('results'),
            style: AppTextStyles.text1.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        ..._cities.map((city) => _buildCityTile(city)),
      ],
    );
  }

  Widget _buildRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.history, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                TranslationService.translate('recent'),
                style: AppTextStyles.text1.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        ..._recent.map((city) => _buildCityTile(city, isRecent: true)),
      ],
    );
  }

  Widget _buildCityTile(Map<String, String> city, {bool isRecent = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCity(city),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRecent
                      ? Colors.grey.shade200
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRecent ? Icons.history : Icons.location_on,
                  color: isRecent ? Colors.grey.shade600 : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city['city']!,
                      style: AppTextStyles.text.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_buildCitySubtitle(city).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _buildCitySubtitle(city),
                        style: AppTextStyles.text4.copyWith(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _buildCitySubtitle(Map<String, String> city) {
    final parts = <String>[];
    if (city['state']!.isNotEmpty) parts.add(city['state']!);
    if (city['country']!.isNotEmpty) parts.add(city['country']!);
    return parts.join(', ');
  }
}
