import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';

class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'CENTRIFUGAL PUMPS';
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _allCategories = [
    {'label': 'CENTRIFUGAL PUMPS', 'icon': Icons.tune},
    {'label': 'SUBMERSIBLE PUMPS', 'icon': Icons.bar_chart},
    {'label': 'PUMP', 'icon': Icons.water_drop},
    {'label': 'OTHERS', 'icon': Icons.extension},
  ];

  static const List<Map<String, dynamic>> _allProducts = [
    {
      'name': 'B-12(S)',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': true,
    },
    {
      'name': 'B-10',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': true,
    },
    {
      'name': 'TH-12',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': true,
    },
    {
      'name': 'APP-13',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'B-12 NR',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'TSW-250',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'PUMP X1',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'PUMP Y2',
      'category': 'CENTRIFUGAL PUMPS',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((product) {
      final matchesCategory = product['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          product['name'].toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationHeader(),
          _buildSearchBar(),
          _buildCategoryTitle(),
          _buildCategoryList(),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _buildProductGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 8.0),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, size: 24, color: AppColors.textDecoration),
            SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location', style: AppTextStyles.text4),
                Text('Bauru', style: AppTextStyles.text),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: CustomSearchBar(
        hintText: 'Search...',
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, top: 0.0, bottom: 10.0),
      child: Text('Select Category', style: AppTextStyles.text),
    );
  }

  Widget _buildCategoryList() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: _allCategories.length,
        itemBuilder: (context, index) {
          final category = _allCategories[index];
          final isSelected = category['label'] == _selectedCategory;
          return CategoryChip(
            label: category['label'],
            icon: category['icon'],
            isSelected: isSelected,
            onTap: () => _onCategorySelected(category['label']),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Center(
        child: Text('Nenhum produto encontrado', style: AppTextStyles.text4),
      );
    }

    return ScrollConfiguration(
      behavior: NoScrollbarScrollBehavior(),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.99,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            category: product['category'],
            productName: product['name'],
            imageUrl: product['image'],
            isSearch: product['isSearch'],
            onActionPressed: () {},
          );
        },
      ),
    );
  }
}
