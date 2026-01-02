import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as coords;
import 'package:provider/provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../widgets/app_buttons.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

class LocationPage extends StatefulWidget {
  final bool isInitialSelection;
  const LocationPage({super.key, this.isInitialSelection = false});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final MapController _mapController = MapController();
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locProv = context.read<LocationProvider>();

      if (widget.isInitialSelection && locProv.city.isEmpty) {
        locProv.initDefaultLocation();
        _mapController.move(
          coords.LatLng(locProv.previewLat, locProv.previewLon),
          13.0,
        );
      } else if (locProv.city.isNotEmpty &&
          locProv.city != context.l10n.translate('choose_location')) {
        locProv.initWithCurrentLocation();
        _mapController.move(coords.LatLng(locProv.lat, locProv.lon), 13.0);
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _moveToCity(double lat, double lon) {
    _mapController.move(coords.LatLng(lat, lon), 13.0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final colors = context.colors;
    final currentPos = coords.LatLng(provider.previewLat, provider.previewLon);
    final isDark = context.theme.brightness == Brightness.dark;

    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: coords.LatLng(
                provider.previewLat,
                provider.previewLon,
              ),
              initialZoom: 13.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.ebara.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPos,
                    width: 120,
                    height: 120,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: AppShadows.sm(colors.shadow),
                          ),
                          child: Text(
                            provider.results.isNotEmpty
                                ? provider.results[provider
                                      .currentIndex]['city']
                                : (provider.city.isEmpty
                                      ? "São Paulo"
                                      : provider.city),
                            style: context.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.location_on,
                          color: colors.primary,
                          size: 45,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                  child: Row(
                    children: [
                      if (!widget.isInitialSelection) ...[
                        AppSquareIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => context.pop(),
                          backgroundColor: colors.primary,
                          iconColor: colors.onPrimary,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Container(
                          height: 55,
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: AppShadows.md(colors.shadow),
                          ),
                          child: Center(
                            child: TextField(
                              controller: _searchController,
                              enabled:
                                  !provider.isGpsLoading && !provider.isLoading,
                              textAlignVertical: TextAlignVertical.center,
                              onSubmitted: (val) async {
                                await provider.search(val);
                                if (provider.results.isNotEmpty) {
                                  _moveToCity(
                                    provider.previewLat,
                                    provider.previewLon,
                                  );
                                  _pageController.jumpToPage(0);
                                }
                              },
                              style: context.titleStyle?.copyWith(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: context.l10n.translate('search'),
                                hintStyle: context.bodySmall,
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: colors.primary,
                                ),
                                border: InputBorder.none,
                                isCollapsed: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (provider.results.isNotEmpty)
                  _buildBottomCard(provider, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard(LocationProvider provider, BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.all(AppDimens.lg),
      padding: const EdgeInsets.all(AppDimens.xl),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        boxShadow: AppShadows.lg(colors.shadow),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60,
            child: PageView.builder(
              controller: _pageController,
              itemCount: provider.results.length,
              physics: provider.isLoading
                  ? const NeverScrollableScrollPhysics()
                  : null,
              onPageChanged: (i) {
                provider.updateIndex(i);
                _moveToCity(provider.previewLat, provider.previewLon);
              },
              itemBuilder: (context, i) {
                final item = provider.results[i];
                return Column(
                  children: [
                    Text(
                      item['city'],
                      style: context.titleStyle?.copyWith(fontSize: 18),
                    ),
                    Text(
                      "${item['state']}, ${item['country']}",
                      style: context.bodyStyle,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppDimens.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSquareIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: provider.currentIndex > 0
                    ? () {
                        if (!provider.isLoading) {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        }
                      }
                    : null,
              ),
              GestureDetector(
                onTap: provider.isLoading
                    ? null
                    : () async {
                        final isInitial = widget.isInitialSelection;
                        final homeProvider = context.read<HomeProvider>();
                        final apiLanguageId = provider.apiLanguageId;
                        final navigator = Navigator.of(context);

                        provider.setGpsLoading(true);
                        final loc = await LocationService().getCurrentCity();
                        if (loc != null) {
                          provider.updateUserLocation(
                            city: loc['city']!,
                            state: loc['state']!,
                            country: loc['country']!,
                            lat: double.tryParse(loc['lat'] ?? '') ?? 0,
                            lon: double.tryParse(loc['lon'] ?? '') ?? 0,
                            saveToCache: true,
                          );
                          if (!mounted) {
                            provider.setGpsLoading(false);
                            return;
                          }

                          homeProvider.reloadData(apiLanguageId);

                          if (isInitial) {
                            context.pushReplacementNamed('/home');
                          } else {
                            navigator.pop();
                          }
                        }
                        provider.setGpsLoading(false);
                      },
                child: Container(
                  width: 75,
                  height: 60,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: provider.isGpsLoading
                      ? Padding(
                          padding: const EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            color: colors.onPrimary,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          Icons.gps_fixed,
                          color: colors.onPrimary,
                          size: 28,
                        ),
                ),
              ),
              AppSquareIconButton(
                icon: Icons.arrow_forward_ios_rounded,
                onTap: provider.currentIndex < provider.results.length - 1
                    ? () {
                        if (!provider.isLoading) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: AppDimens.lg),
          AppPrimaryButton(
            onPressed: provider.isLoading
                ? null
                : () {
                    final city = provider.results[provider.currentIndex];
                    provider.updateUserLocation(
                      city: city['city'],
                      state: city['state'],
                      country: city['country'],
                      lat: double.tryParse(city['lat'].toString()) ?? 0,
                      lon: double.tryParse(city['lon'].toString()) ?? 0,
                      saveToCache: true,
                    );

                    context.read<HomeProvider>().reloadData(
                      provider.apiLanguageId,
                    );

                    if (widget.isInitialSelection) {
                      final authProvider = context.read<AuthProvider>();

                      if (authProvider.status == AuthStatus.unauthenticated) {
                        context.pushReplacementNamed('/login');
                      } else {
                        context.pushReplacementNamed('/home');
                      }
                    } else {
                      context.pop();
                    }
                  },
            isLoading: provider.isLoading,
            text: context.l10n.translate('select_location').toUpperCase(),
          ),
        ],
      ),
    );
  }
}
