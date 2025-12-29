import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as coords;
import 'package:provider/provider.dart';
import '../../core/providers/location_provider.dart';
import '../../core/providers/home_provider.dart';
import '../../core/services/location_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
      final l10n = AppLocalizations.of(context)!;

      if (widget.isInitialSelection && locProv.city.isEmpty) {
        locProv.initDefaultLocation();
        _mapController.move(
          coords.LatLng(locProv.previewLat, locProv.previewLon),
          13.0,
        );
      } else if (locProv.city.isNotEmpty &&
          locProv.city != l10n.translate('choose_location')) {
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
    final currentPos = coords.LatLng(provider.previewLat, provider.previewLon);
    final l10n = AppLocalizations.of(context)!;

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
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            provider.results.isNotEmpty
                                ? provider.results[provider
                                      .currentIndex]['city']
                                : (provider.city.isEmpty
                                      ? "São Paulo"
                                      : provider.city),
                            style: AppTextStyles.text4.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
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
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Row(
                    children: [
                      if (!widget.isInitialSelection) ...[
                        IconButton.filled(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(45, 45),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            enabled:
                                !provider.isGpsLoading && !provider.isLoading,
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
                            decoration: InputDecoration(
                              hintText: l10n.translate('search'),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
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
                    Text(item['city'], style: AppTextStyles.text),
                    Text(
                      "${item['state']}, ${item['country']}",
                      style: AppTextStyles.text4,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBtn(
                Icons.arrow_back_ios_rounded,
                provider.currentIndex > 0
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
                        final loc = await LocationService.getCurrentCity();
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
                            navigator.pushReplacementNamed('/home');
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
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: provider.isGpsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(
                          Icons.gps_fixed,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
              _NavBtn(
                Icons.arrow_forward_ios_rounded,
                provider.currentIndex < provider.results.length - 1
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
          const SizedBox(height: 20),
          ElevatedButton(
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
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    l10n.translate('select_location').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _NavBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: onTap != null
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        foregroundColor: onTap != null
            ? AppColors.primary
            : Colors.grey.shade300,
        minimumSize: const Size(55, 55),
      ),
    );
  }
}
