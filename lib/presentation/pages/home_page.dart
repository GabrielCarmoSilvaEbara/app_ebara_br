import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/category_chip.dart';
import '../widgets/product_card.dart';
import '../widgets/product_card_skeleton.dart';
import '../services/location_service.dart';
import '../services/translation_service.dart';
import '../widgets/location_selector_sheet.dart';

class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(context, child, details) {
    return child;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  var selectedCategory = 'centrifugal_pumps';
  var searchQuery = '';
  var city = '';
  var state = '';
  var country = '';

  bool isLoading = false;

  List<Map<String, dynamic>> get categories => [
    {'label': 'centrifugal_pumps', 'icon': Icons.tune},
    {'label': 'submersible_pumps', 'icon': Icons.bar_chart},
    {'label': 'pump', 'icon': Icons.water_drop},
    {'label': 'others', 'icon': Icons.extension},
  ];

  static const products = [
    {
      'name': 'B-12(S)',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': true,
    },
    {
      'name': 'B-10',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': true,
    },
    {
      'name': 'TH-12',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': true,
    },
    {
      'name': 'APP-13',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'B-12 NR',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'TSW-250',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'B-3 NR',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'TS-250',
      'category': 'centrifugal_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'PUMP X1',
      'category': 'submersible_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
    {
      'name': 'PUMP Y2',
      'category': 'submersible_pumps',
      'image': 'assets/images/pump_example.png',
      'isSearch': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    city = TranslationService.translate('search');
    initLocation();
  }

  Future<void> initLocation() async {
    final location = await LocationService.getCurrentCity();

    if (!mounted) return;

    if (location == null || location['city']!.isEmpty) {
      setState(() => city = TranslationService.translate('choose_location'));
    } else {
      TranslationService.setLanguageByCountry(location['country']!);
      setState(() {
        city = location['city']!;
        country = location['country']!;
      });
    }
  }

  void triggerSkeleton() {
    setState(() => isLoading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => isLoading = false);
    });
  }

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      final matchesCategory = product['category'] == selectedCategory;
      final productName = product['name'] as String;
      final matchesSearch =
          searchQuery.isEmpty ||
          productName.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void openLocationSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => LocationSelectorSheet(
        onSelected: (c, s, co) {
          TranslationService.setLanguageByCountry(co);
          setState(() {
            city = c;
            state = s;
            country = co;
          });
        },
      ),
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildLocationHeader(),
          buildSearchBar(),
          buildCategoryTitle(),
          buildCategoryList(),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: buildProductGrid(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLocationHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
      child: Center(
        child: GestureDetector(
          onTap: openLocationSelector,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                size: 24,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TranslationService.translate('location'),
                    style: AppTextStyles.text4,
                  ),
                  Text(city, style: AppTextStyles.text),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: CustomSearchBar(
        hintText: TranslationService.translate('search'),
        onChanged: (query) {
          triggerSkeleton();
          setState(() => searchQuery = query);
        },
      ),
    );
  }

  Widget buildCategoryTitle() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Text(
        TranslationService.translate('select_category'),
        style: AppTextStyles.text,
      ),
    );
  }

  Widget buildCategoryList() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category['label'] == selectedCategory;

          return CategoryChip(
            label: TranslationService.translate(category['label']),
            icon: category['icon'],
            isSelected: isSelected,
            onTap: () {
              triggerSkeleton();
              setState(() => selectedCategory = category['label'] as String);
            },
          );
        },
      ),
    );
  }

  Widget buildProductGrid() {
    if (isLoading) {
      return GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.99,
        ),
        itemBuilder: (_, __) => const ProductCardSkeleton(),
      );
    }

    final prods = filteredProducts;

    if (prods.isEmpty) {
      return Center(
        child: Text(
          TranslationService.translate('no_products_found'),
          style: AppTextStyles.text4,
        ),
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
        itemCount: prods.length,
        itemBuilder: (context, index) {
          final product = prods[index];
          return ProductCard(
            category: TranslationService.translate(product['category']),
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
