import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../theme/app_colors.dart';
import '../../core/services/location_service.dart';

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
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.length < _minQueryLength) {
      setState(() => _error = context.l10n.translate('error_min_letters'));
      return;
    }

    _focusNode.unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await LocationService().searchCities(query: query);
      if (mounted) {
        setState(() => _cities = result);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = context.l10n.translate('error_fetching_cities'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectCity(Map<String, String> city) {
    FocusManager.instance.primaryFocus?.unfocus();
    _addToRecent(city);
    widget.onSelected(city['city']!, city['state']!, city['country']!);
    context.pop();
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
    final keyboardHeight = context.mediaQuery.viewInsets.bottom;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchField(isDark),
                  if (_error != null) _buildError(),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: _buildContent(isDark),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: _buildSearchButton(),
          ),
          SizedBox(height: keyboardHeight),
        ],
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
        border: Border(bottom: BorderSide(color: context.theme.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            context.l10n.translate('select_location'),
            style: context.textTheme.displayLarge?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark) {
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
      style: context.textTheme.displayMedium?.copyWith(fontSize: 16),
      decoration: InputDecoration(
        hintText: context.l10n.translate('enter_city_name'),
        hintStyle: context.textTheme.labelMedium?.copyWith(color: Colors.grey),
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
        fillColor: isDark ? context.theme.cardColor : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1.5,
          ),
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
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
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
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
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
                    context.l10n.translate('search_button'),
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

  Widget _buildContent(bool isDark) {
    if (_cities.isNotEmpty) {
      return Container(
        key: const ValueKey('cityList'),
        child: _buildCityList(isDark),
      );
    }

    if (_recent.isNotEmpty && !_loading) {
      return Container(
        key: const ValueKey('recentList'),
        child: _buildRecent(isDark),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildCityList(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.l10n.translate('results'),
            style: context.textTheme.displayMedium?.copyWith(
              fontSize: 15,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
        ),
        ..._cities.map((city) => _buildCityTile(city, isDark)),
      ],
    );
  }

  Widget _buildRecent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 18,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.translate('recent'),
                style: context.textTheme.displayMedium?.copyWith(
                  fontSize: 15,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
        ..._recent.map((city) => _buildCityTile(city, isDark, isRecent: true)),
      ],
    );
  }

  Widget _buildCityTile(
    Map<String, String> city,
    bool isDark, {
    bool isRecent = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectCity(city),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? context.theme.cardColor : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRecent
                      ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRecent ? Icons.history : Icons.location_on,
                  color: isRecent
                      ? (isDark ? Colors.white70 : Colors.grey.shade600)
                      : AppColors.primary,
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
                      style: context.textTheme.displayMedium?.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    if (_buildCitySubtitle(city).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _buildCitySubtitle(city),
                        style: context.textTheme.labelMedium?.copyWith(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white30 : Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildCitySubtitle(Map<String, String> city) {
    final parts = <String>[];
    if (city['state']!.isNotEmpty) {
      parts.add(city['state']!);
    }
    if (city['country']!.isNotEmpty) {
      parts.add(city['country']!);
    }
    return parts.join(', ');
  }
}
