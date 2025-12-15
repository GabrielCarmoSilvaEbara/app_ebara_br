import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/location_service.dart';

class LocationSelectorSheet extends StatefulWidget {
  final Function(String city, String district, String country) onSelected;

  const LocationSelectorSheet({super.key, required this.onSelected});

  @override
  State<LocationSelectorSheet> createState() => _LocationSelectorSheetState();
}

class _LocationSelectorSheetState extends State<LocationSelectorSheet> {
  final TextEditingController _controller = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Map<String, String>> _cities = [];
  final List<Map<String, String>> _recent = [];

  Future<void> _search() async {
    final query = _controller.text.trim();

    if (query.length < 3) {
      setState(() => _error = 'Type at least 3 letters');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await LocationService.searchCities(query: query);
      setState(() => _cities = result);
    } catch (_) {
      setState(() => _error = 'Error fetching cities');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _selectCity(Map<String, String> city) {
    _recent.removeWhere(
      (e) => e['city'] == city['city'] && e['district'] == city['district'],
    );

    _recent.insert(0, city);
    if (_recent.length > 5) _recent.removeLast();

    widget.onSelected(city['city']!, city['state']!, city['country']!);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Enter the city name',
                      hintStyle: AppTextStyles.text4,
                      prefixIcon: const Icon(
                        Icons.location_city,
                        color: AppColors.primary,
                      ),
                      enabledBorder: _border(),
                      focusedBorder: _border(),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: AppTextStyles.text4.copyWith(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 16),

                  _buildSearchButton(),

                  const SizedBox(height: 16),

                  if (_loading) const CircularProgressIndicator(),

                  if (!_loading && _cities.isEmpty && _recent.isNotEmpty)
                    _buildRecent(),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _cities.length,
                      itemBuilder: (_, index) {
                        final city = _cities[index];
                        return ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: AppColors.primary,
                          ),
                          title: Text(city['city']!),
                          subtitle: Text(
                            [
                              if (city['state']!.isNotEmpty) city['state'],
                              if (city['country']!.isNotEmpty) city['country'],
                            ].join(', '),
                          ),
                          onTap: () => _selectCity(city),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text('Select location', style: AppTextStyles.text),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _loading ? null : _search,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Text('Search', style: AppTextStyles.text2.copyWith(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recentes', style: AppTextStyles.text1),
        const SizedBox(height: 8),
        ..._recent.map((city) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(city['city']!),
            subtitle: Text(
              [
                if (city['state']!.isNotEmpty) city['state'],
                if (city['country']!.isNotEmpty) city['country'],
              ].join(', '),
            ),
            onTap: () => _selectCity(city),
          );
        }),
      ],
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    );
  }
}
