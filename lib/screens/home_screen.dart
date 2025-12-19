import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controllers/theme_controller.dart';
import '../widgets/animated_banner_explicit.dart';
import '../widgets/animated_banner_implicit.dart';
import '../widgets/benefit_tile.dart';
import '../widgets/category_card.dart';
import '../widgets/gradient_button.dart';
import '../widgets/product_card.dart';
import '../widgets/rounded_icon_button.dart';
import 'cart_screen.dart';
import 'cloud_notes_screen.dart';
import 'notification_center_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'location_center_screen.dart';
import '../routes/app_routes.dart';
import '../services/product_service.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _handleTabChange(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 30,
            color: isActive ? const Color(0xFFFF5E9D) : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isActive ? const Color(0xFFFF5E9D) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeLanding(onOpenSearch: () => Get.to(() => const SearchScreen())),
      const WishlistScreen(),
      const CloudNotesScreen(),
      const NotificationCenterScreen(),
      const ProfileScreen(),
      const LocationCenterScreen(),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = theme.colorScheme.surface;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      // Floating button (tombol Location)
      floatingActionButton: GestureDetector(
        onTap: () => setState(() => _currentIndex = 5),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8FB1), Color(0xFFFF5E9D)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5E9D).withOpacity(0.25),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.location_on, size: 34, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, "Home", 0),
              _navItem(Icons.favorite_border, "Wishlist", 1),
              const SizedBox(width: 30),
              _navItem(Icons.note_alt_outlined, "Catatan", 2),
              _navItem(Icons.notifications_active_outlined, "Notif", 3),
              _navItem(Icons.person, "Profile", 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLanding extends StatelessWidget {
  const _HomeLanding({required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  List<Map<String, dynamic>> get categories => [
    {
      'title': 'Dresses',
      'subtitle': '45 items',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF8FB1), Color(0xFFFF5E9D)],
      ),
    },
    {
      'title': 'Jackets',
      'subtitle': '32 items',
      'gradient': const LinearGradient(
        colors: [Color(0xFFB19CFF), Color(0xFF7B5BFF)],
      ),
    },
    {
      'title': 'Sweaters',
      'subtitle': '28 items',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFC48F), Color(0xFFFF9264)],
      ),
    },
    {
      'title': 'Jeans',
      'subtitle': '38 items',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFD1D1), Color(0xFFFF9190)],
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final productService = Get.find<ProductService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: background,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.heroTop,
                  AppSpacing.page,
                  32,
                ),
                decoration: const BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: AppColors.primaryPink,
                          ),
                        ),
                        AppSpacing.hItem,
                        const Text(
                          'Wida Collection',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        RoundedIconButton(
                          icon: Icons.shopping_bag_outlined,
                          onPressed: () => Get.to(() => const CartScreen()),
                        ),
                        AppSpacing.hItem,
                        _ThemeToggle(controller: themeController),
                      ],
                    ),
                    AppSpacing.vSection,
                    _SearchField(onTap: onOpenSearch),
                    AppSpacing.vSection,
                    const Chip(label: Text('Vintage Fashion')),
                    const SizedBox(height: 16),
                    Text(
                      'Temukan Gaya Unikmu',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Koleksi pilihan baju thrift berkualitas untuk wanita modern.',
                      style: TextStyle(color: AppColors.softGray),
                    ),
                    AppSpacing.vSection,
                    GradientButton(
                      label: 'Shop Now',
                      onPressed: onOpenSearch,
                      expanded: false,
                    ),
                  ],
                ),
              ),
              const _PromoBannerSection(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.section,
                  AppSpacing.page,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Categories',
                      subtitle: 'Pilih kategori favorit',
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: categories.length,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                      itemBuilder: (context, index) {
                        final data = categories[index];
                        return CategoryCard(
                          title: data['title'] as String,
                          subtitle: data['subtitle'] as String,
                          gradient: data['gradient'] as Gradient,
                          onTap: () => Get.snackbar(
                            'Segera hadir',
                            '${data['title']} collection sedang dikuratori',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              AppSpacing.vSection,
              Padding(
                padding: AppSpacing.pagePadding,
                child: _SectionHeader(
                  title: 'New Arrivals',
                  subtitle: 'Koleksi terbaru untuk kamu ✨',
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: AppSpacing.pagePadding,
                child: Obx(() {
                  final products = productService.products;
                  if (productService.isLoading.value && products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('Produk belum tersedia. Coba segarkan.'),
                      ),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        badge: index.isEven ? 'Excellent' : 'Very Good',
                        onTap: () =>
                            Get.to(() => ProductDetailScreen(product: product)),
                      );
                    },
                  );
                }),
              ),
              AppSpacing.vSection,
              Container(
                width: double.infinity,
                margin: AppSpacing.pagePadding,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? scheme.surface : AppColors.lavender,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mengapa Wida Collection?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Koleksi thrift fashion berkualitas tinggi dengan harga terjangkau',
                    ),
                    const SizedBox(height: 16),
                    const BenefitTile(
                      icon: Icons.verified_user,
                      title: 'Kualitas Terjamin',
                      subtitle: 'Setiap produk melalui quality check ketat',
                    ),
                    AppSpacing.vItem,
                    const BenefitTile(
                      icon: Icons.auto_awesome,
                      title: 'Unique Pieces',
                      subtitle:
                          'Item unik yang tidak akan kamu temukan di tempat lain',
                    ),
                    AppSpacing.vItem,
                    const BenefitTile(
                      icon: Icons.eco,
                      title: 'Sustainable',
                      subtitle: 'Belanja thrift berarti peduli lingkungan',
                    ),
                  ],
                ),
              ),
              AppSpacing.vSection,
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppColors.softGray)),
      ],
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  static const _prompts = [
    'Cari Pakaian Wanita',
    'Cari Pakaian Pria',
    'Dress Vintage Favorit',
    'Jaket Denim Terbaru',
    'Sweater Hangat',
    'Celana Jeans Classic',
    'Aksesoris Retro',
    'Sepatu Santai',
  ];

  late int _currentPrompt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentPrompt = 0;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      setState(() {
        _currentPrompt = (_currentPrompt + 1) % _prompts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surface;
    final borderColor = AppColors.primaryPink.withOpacity(0.2);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: AppColors.primaryPink.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.primaryPink),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Text(
                  _prompts[_currentPrompt],
                  key: ValueKey(_currentPrompt),
                  style: const TextStyle(
                    color: AppColors.primaryPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.softGray,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLight = controller.themeMode.value == ThemeMode.light;
      return GestureDetector(
        onTap: () =>
            controller.setThemeMode(isLight ? ThemeMode.dark : ThemeMode.light),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 64,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isLight
                ? const LinearGradient(
                    colors: [Color(0xFFFFE4F2), Color(0xFFFFB5D9)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFF2D2D2D), Color(0xFF121212)],
                  ),
            boxShadow: [
              if (isLight)
                BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: isLight
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isLight ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                    size: 16,
                    color: isLight
                        ? AppColors.primaryPink
                        : Colors.deepPurpleAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PromoBannerSection extends StatefulWidget {
  const _PromoBannerSection();

  @override
  State<_PromoBannerSection> createState() => _PromoBannerSectionState();
}

class _PromoBannerSectionState extends State<_PromoBannerSection> {
  late final PageController _pageController;
  int _currentPage = 0;
  late final List<double> _collapsedHeights;
  late final List<double> _bannerHeights;

  @override
  void initState() {
    super.initState();
    _collapsedHeights = const [
      AnimatedBannerImplicit.collapsedHeight,
      AnimatedBannerExplicit.collapsedHeight,
    ];
    _bannerHeights = List<double>.from(_collapsedHeights);
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _bannerCount => _collapsedHeights.length;

  double get _currentBannerHeight => _bannerHeights[_currentPage];

  double get _currentCollapsedHeight => _collapsedHeights[_currentPage];

  double get _indicatorOffset {
    final difference = _currentBannerHeight - _currentCollapsedHeight;
    return difference > 0 ? difference : 0;
  }

  double get _indicatorMarginTop => 6 + _indicatorOffset;

  void _handleBannerHeightChange(int index, double height) {
    if (_bannerHeights[index] == height) return;
    _bannerHeights[index] = height;
    if (index == _currentPage && mounted) {
      setState(() {});
    }
  }

  Widget _buildBanner(int index) {
    switch (index) {
      case 0:
        return AnimatedBannerImplicit(
          onHeightChanged: (height) => _handleBannerHeightChange(index, height),
        );
      case 1:
      default:
        return AnimatedBannerExplicit(
          onHeightChanged: (height) => _handleBannerHeightChange(index, height),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vSection,
        Padding(
          padding: AppSpacing.pagePadding,
          child: const _SectionHeader(
            title: 'Hot Promo',
            subtitle: 'Temukan Promo Terbaik Hari Ini',
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: AppSpacing.pagePadding,
          child: SizedBox(
            height: AnimatedBannerExplicit.expandedHeight,
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              padEnds: false,
              itemCount: _bannerCount,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  right: index == _bannerCount - 1 ? 0 : 12,
                ),
                child: _buildBanner(index),
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: _indicatorMarginTop),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _bannerCount,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.primaryPink
                      : AppColors.primaryPink.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wida Collection',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your destination for quality vintage fashion',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          const Text(
            'widacollection@gmail.com',
            style: TextStyle(color: Colors.white),
          ),
          const Text(
            '+62 812-3456-7890',
            style: TextStyle(color: Colors.white),
          ),
          const Text('@widhathrift', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          const Text(
            '© 2025 Wida Collection. All rights reserved.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
