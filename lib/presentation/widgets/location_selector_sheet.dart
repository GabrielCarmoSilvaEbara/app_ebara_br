import 'package:flutter/material.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/services/location_service.dart';
import 'app_buttons.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

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
    final colors = context.colors;

    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppShadows.sm(colors.shadow),
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
                  _buildSearchField(),
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
                    child: _buildContent(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: AppPrimaryButton(
              onPressed: _loading ? null : _search,
              text: context.l10n.translate('search_button'),
              isLoading: _loading,
              icon: Icons.search,
            ),
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
        color: context.colors.outline.withValues(alpha: 0.3),
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
          Icon(Icons.location_on, color: context.colors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            context.l10n.translate('select_location'),
            style: context.titleStyle?.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    final colors = context.colors;

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
      style: context.subtitleStyle?.copyWith(fontSize: 16),
      decoration: InputDecoration(
        hintText: context.l10n.translate('enter_city_name'),
        hintStyle: context.bodySmall,
        prefixIcon: Icon(Icons.search, color: colors.primary),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
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
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(
            color: colors.outline.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(color: colors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
    );
  }

  Widget _buildError() {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_cities.isNotEmpty) {
      return Container(
        key: const ValueKey('cityList'),
        child: _buildCityList(),
      );
    }

    if (_recent.isNotEmpty && !_loading) {
      return Container(
        key: const ValueKey('recentList'),
        child: _buildRecent(),
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }

  Widget _buildCityList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            context.l10n.translate('results'),
            style: context.bodySmall?.copyWith(fontSize: 15),
          ),
        ),
        ..._cities.map((city) => _buildCityTile(city)),
      ],
    );
  }

  Widget _buildRecent() {
    final colors = context.colors;

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
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.translate('recent'),
                style: context.bodySmall?.copyWith(fontSize: 15),
              ),
            ],
          ),
        ),
        ..._recent.map((city) => _buildCityTile(city, isRecent: true)),
      ],
    );
  }

  Widget _buildCityTile(Map<String, String> city, {bool isRecent = false}) {
    final colors = context.colors;

    return Material(
      color: colors.surface.withValues(alpha: 0),
      child: InkWell(
        onTap: () => _selectCity(city),
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: colors.outline.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRecent
                      ? colors.onSurface.withValues(alpha: 0.05)
                      : colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isRecent ? Icons.history : Icons.location_on,
                  color: isRecent
                      ? colors.onSurface.withValues(alpha: 0.6)
                      : colors.primary,
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
                      style: context.subtitleStyle?.copyWith(fontSize: 15),
                    ),
                    if (_buildCitySubtitle(city).isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _buildCitySubtitle(city),
                        style: context.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.3),
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
