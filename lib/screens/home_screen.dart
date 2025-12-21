import 'dart:ui';

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
import '../widgets/custom_nav_bar.dart';
import '../widgets/rotating_search_text.dart';
import 'cart_screen.dart';
import 'cloud_notes_screen.dart';
import 'notification_center_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Pages for the bottom nav
    final pages = [
      _HomeLanding(onOpenSearch: () => Get.to(() => const SearchScreen())),
      const WishlistScreen(),
      const CloudNotesScreen(),
      const NotificationCenterScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      // Use Stack only for the Home tab (index 0) to support the sticky bar overlay.
      // Other tabs behave normally.
      body: _currentIndex == 0
          ? Stack(
              children: [
                // Page Content
                pages[0],
                // Sticky Header (Overlay)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _StickyTopBar(
                    onOpenSearch: () => Get.to(() => const SearchScreen()),
                  ),
                ),
              ],
            )
          : IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _StickyTopBar extends StatelessWidget {
  const _StickyTopBar({required this.onOpenSearch});

  final VoidCallback onOpenSearch;

  @override
  Widget build(BuildContext context) {
    // Glassmorphism effect or solid with high opacity for premium feel
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xB31E1E1E) // Dark transparent
        : const Color(0xB3FFFFFF); // White transparent

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: bgColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 12,
            left: 16,
            right: 16,
          ),
          child: Row(
            children: [
              // Logo Rounded
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPink.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Expanded Search Bar
              Expanded(
                child: GestureDetector(
                  onTap: onOpenSearch,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryPink.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search,
                          color: AppColors.primaryPink,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RotatingSearchText(
                            textColor: isDark
                                ? Colors.white60
                                : Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Cart
              RoundedIconButton(
                icon: Icons.shopping_bag_outlined,
                onPressed: () => Get.to(() => const CartScreen()),
                // Make it slightly smaller to fit
                // radius is not directly exposed in RoundedIconButton constructor usually?
                // Assuming it uses default size, which is fine.
              ),

              const SizedBox(width: 8),

              // Theme Toggle
              _ThemeToggle(controller: Get.find<ThemeController>()),
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
      'gradient': const LinearGradient(
        colors: [Color(0xFFFF8FB1), Color(0xFFFF5E9D)],
      ),
    },
    {
      'title': 'Jackets',
      'gradient': const LinearGradient(
        colors: [Color(0xFFB19CFF), Color(0xFF7B5BFF)],
      ),
    },
    {
      'title': 'Sweaters',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFC48F), Color(0xFFFF9264)],
      ),
    },
    {
      'title': 'Jeans',
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFD1D1), Color(0xFFFF9190)],
      ),
    },
    {
      'title': 'Pants',
      // Reuse existing gradient tokens/colors (no new palette)
      'gradient': const LinearGradient(
        colors: [Color(0xFFFFC48F), Color(0xFFFF9264)],
      ),
    },
    {
      'title': 'T-Shirts',
      // Reuse existing gradient tokens/colors (no new palette)
      'gradient': const LinearGradient(
        colors: [Color(0xFFB19CFF), Color(0xFF7B5BFF)],
      ),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final productService = Get.find<ProductService>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    // Calculate top padding to clear the sticky bar
    // Sticky bar height approx: StatusBar + 8 + 40 + 12 = StatusBar + 60
    final topPadding = MediaQuery.of(context).padding.top + 60;

    return Container(
      color: background,
      child: SafeArea(
        bottom: false,
        top: false, // Handle top padding manually in the content
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  topPadding + 24, // Add extra spacing below the bar
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
                  AppSpacing.item, // rapatkan heading kategori ke slider
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
                    Obx(() {
                      final items = productService.products;

                      final counts = <String, int>{
                        for (final c in categories) (c['title'] as String): 0,
                      };
                      for (final p in items) {
                        final key = p.resolvedCategory;
                        final current = counts[key];
                        if (current != null) counts[key] = current + 1;
                      }

                      return GridView.builder(
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
                          final title = data['title'] as String;
                          final subtitle = '${counts[title] ?? 0} items';
                          return CategoryCard(
                            title: title,
                            subtitle: subtitle,
                            gradient: data['gradient'] as Gradient,
                            onTap: () => Get.to(
                              () => SearchScreen(initialCategory: title),
                            ),
                          );
                        },
                      );
                    }),
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
                    final message = productService.lastError.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          message == null
                              ? 'Produk belum tersedia. Coba segarkan.'
                              : 'Gagal memuat produk: $message',
                          textAlign: TextAlign.center,
                        ),
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
    final extraSpace =
        AnimatedBannerExplicit.expandedHeight - _currentBannerHeight;
    final indicatorSpacing = (6 - extraSpace).clamp(-24, 12).toDouble();
    final indicatorMargin = indicatorSpacing > 0 ? indicatorSpacing : 0.0;
    final indicatorShift = indicatorSpacing < 0 ? indicatorSpacing : 0.0;
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
        SizedBox(
          height: AnimatedBannerExplicit.expandedHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            padEnds: false,
            itemCount: _bannerCount,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? AppSpacing.page : 12,
                right: index == _bannerCount - 1 ? AppSpacing.page : 12,
              ),
              child: _buildBanner(index),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(top: indicatorMargin),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: indicatorShift),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: child,
              );
            },
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
