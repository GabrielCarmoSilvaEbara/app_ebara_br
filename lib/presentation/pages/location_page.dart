import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as coords;
import 'package:provider/provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/widget_extensions.dart';
import '../../core/router/app_router.dart';
import '../../core/constants/app_constants.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_search_bar.dart';
import '../theme/app_dimens.dart';
import '../theme/app_shadows.dart';

class LocationPage extends StatefulWidget {
  final bool isInitialSelection;
  const LocationPage({super.key, this.isInitialSelection = false});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late final TextEditingController _searchController;
  late final MapController _mapController;
  late final PageController _carouselController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _mapController = MapController();
    _carouselController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locProv = context.read<LocationProvider>();
      final isChoosing =
          locProv.city == context.l10n.translate('choose_location');

      if (widget.isInitialSelection && locProv.city.isEmpty) {
        locProv.initDefaultLocation();
      } else if (locProv.city.isNotEmpty && !isChoosing) {
        locProv.initWithCurrentLocation();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    _carouselController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted(String value) {
    context.read<LocationProvider>().performSearch(value);
  }

  void _moveToLocation(double lat, double lon) {
    try {
      _mapController.move(coords.LatLng(lat, lon), 13.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _LocationMapLayers(mapController: _mapController),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimens.lg,
                    AppDimens.xl,
                    AppDimens.lg,
                    AppDimens.sm,
                  ),
                  child: Row(
                    children: [
                      if (!widget.isInitialSelection) ...[
                        AppSquareIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => context.pop(),
                          backgroundColor: context.colors.primary,
                          iconColor: context.colors.onPrimary,
                        ),
                        AppDimens.sm.hGap,
                      ],
                      Expanded(
                        child: Consumer<LocationProvider>(
                          builder: (context, provider, _) {
                            return AppSearchBar(
                              controller: _searchController,
                              hintText: context.l10n.translate('search'),
                              showFilterButton: false,
                              enabled:
                                  !provider.isGpsLoading && !provider.isLoading,
                              onSubmitted: _onSearchSubmitted,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Consumer<LocationProvider>(
                  builder: (context, provider, _) {
                    if (provider.results.isNotEmpty) {
                      _moveToLocation(provider.previewLat, provider.previewLon);
                      if (_carouselController.hasClients &&
                          _carouselController.page?.round() !=
                              provider.currentIndex) {
                        _carouselController.jumpToPage(provider.currentIndex);
                      }

                      return BottomLocationCard(
                        isInitialSelection: widget.isInitialSelection,
                        carouselController: _carouselController,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationMapLayers extends StatelessWidget {
  final MapController mapController;
  const _LocationMapLayers({required this.mapController});

  @override
  Widget build(BuildContext context) {
    final isDark = context.theme.brightness == Brightness.dark;
    final tileUrl = isDark
        ? AppConstants.mapTileUrlDark
        : AppConstants.mapTileUrlLight;

    return Selector<LocationProvider, (double, double)>(
      selector: (_, p) => (p.previewLat, p.previewLon),
      builder: (context, coordsData, _) {
        final currentPos = coords.LatLng(coordsData.$1, coordsData.$2);
        return FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: currentPos,
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
                  width: AppDimens.mapMarkerSize,
                  height: AppDimens.mapMarkerSize,
                  child: const LocationMarker(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class BottomLocationCard extends StatelessWidget {
  final bool isInitialSelection;
  final PageController carouselController;

  const BottomLocationCard({
    super.key,
    required this.isInitialSelection,
    required this.carouselController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final provider = context.read<LocationProvider>();

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
            height: AppDimens.cardHeightSm,
            child: Selector<LocationProvider, List<Map<String, dynamic>>>(
              selector: (_, p) => p.results,
              builder: (context, results, _) {
                return PageView.builder(
                  controller: carouselController,
                  itemCount: results.length,
                  physics:
                      context.select<LocationProvider, bool>((p) => p.isLoading)
                      ? const NeverScrollableScrollPhysics()
                      : null,
                  onPageChanged: (i) => provider.updateIndex(i),
                  itemBuilder: (context, i) {
                    final item = results[i];
                    return Column(
                      children: [
                        Text(
                          item['city'],
                          style: context.titleStyle?.copyWith(
                            fontSize: AppDimens.fontXxl,
                          ),
                        ),
                        Text(
                          "${item['state']}, ${item['country']}",
                          style: context.bodyStyle,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          AppDimens.lg.vGap,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Selector<LocationProvider, int>(
                selector: (_, p) => p.currentIndex,
                builder: (context, index, _) {
                  return AppSquareIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: index > 0
                        ? () => carouselController.previousPage(
                            duration: AppDimens.durationNormal,
                            curve: Curves.ease,
                          )
                        : null,
                  );
                },
              ),
              GestureDetector(
                onTap: () async {
                  if (provider.isLoading) return;
                  final homeProvider = context.read<HomeProvider>();
                  final apiLanguageId = provider.apiLanguageId;
                  final success = await provider.useCurrentLocation();

                  if (success && context.mounted) {
                    homeProvider.reloadData(apiLanguageId);
                    if (isInitialSelection) {
                      context.pushReplacementNamed(AppRoutes.home);
                    } else {
                      context.pop();
                    }
                  }
                },
                child: Container(
                  width: AppDimens.locationButtonWidth,
                  height: AppDimens.locationButtonHeight,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Selector<LocationProvider, bool>(
                    selector: (_, p) => p.isGpsLoading,
                    builder: (context, isGpsLoading, _) {
                      return isGpsLoading
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
                              size: AppDimens.iconXxl,
                            );
                    },
                  ),
                ),
              ),
              Selector<LocationProvider, (int, int)>(
                selector: (_, p) => (p.currentIndex, p.results.length),
                builder: (context, data, _) {
                  return AppSquareIconButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    onTap: data.$1 < data.$2 - 1
                        ? () => carouselController.nextPage(
                            duration: AppDimens.durationNormal,
                            curve: Curves.ease,
                          )
                        : null,
                  );
                },
              ),
            ],
          ),
          AppDimens.lg.vGap,
          Selector<LocationProvider, bool>(
            selector: (_, p) => p.isLoading,
            builder: (context, isLoading, _) {
              return AppPrimaryButton(
                onPressed: isLoading
                    ? null
                    : () {
                        provider.selectLocationFromIndex(provider.currentIndex);
                        context.read<HomeProvider>().reloadData(
                          provider.apiLanguageId,
                        );

                        if (isInitialSelection) {
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.status ==
                              AuthStatus.unauthenticated) {
                            context.pushReplacementNamed(AppRoutes.login);
                          } else {
                            context.pushReplacementNamed(AppRoutes.home);
                          }
                        } else {
                          context.pop();
                        }
                      },
                isLoading: isLoading,
                text: context.l10n.translate('select_location').toUpperCase(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class LocationMarker extends StatelessWidget {
  const LocationMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.xs,
            vertical: AppDimens.xxs,
          ),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            boxShadow: AppShadows.sm(colors.shadow),
          ),
          child:
              Selector<
                LocationProvider,
                (List<Map<String, dynamic>>, int, String)
              >(
                selector: (_, p) => (p.results, p.currentIndex, p.city),
                builder: (context, data, _) {
                  final text = data.$1.isNotEmpty
                      ? data.$1[data.$2]['city']
                      : (data.$3.isEmpty ? "São Paulo" : data.$3);
                  return Text(
                    text,
                    style: context.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimens.fontXs,
                    ),
                  );
                },
              ),
        ),
        Icon(Icons.location_on, color: colors.primary, size: AppDimens.iconGps),
      ],
    );
  }
}
