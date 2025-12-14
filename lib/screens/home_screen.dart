import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controllers/theme_controller.dart';
import '../data/dummy_products.dart';
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
import 'wishlist_screen.dart';
import 'location_center_screen.dart';
import '../routes/app_routes.dart';

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
      _HomeLanding(onNavigateToTab: _handleTabChange),
      const SearchScreen(),
      const LocationCenterScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barColor = theme.colorScheme.surface;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      // Floating button (tombol Location)
      floatingActionButton: GestureDetector(
        onTap: () => setState(() => _currentIndex = 2),
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
              _navItem(Icons.search, "Search", 1),

              const SizedBox(width: 30),

              _navItem(Icons.shopping_bag, "Cart", 3),
              _navItem(Icons.person, "Profile", 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeLanding extends StatelessWidget {
  const _HomeLanding({required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

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

  List<_FeatureShortcutData> get experiments => [
    _FeatureShortcutData(
      icon: Icons.favorite_border,
      title: 'Wishlist & Restock',
      description: 'Simpan produk favorit offline & sinkron Supabase.',
      destinationBuilder: (_) => const WishlistScreen(),
    ),
    _FeatureShortcutData(
      icon: Icons.cloud_outlined,
      title: 'Catatan Cloud',
      description: 'Sinkron otomatis via Supabase.',
      destinationBuilder: (_) => const CloudNotesScreen(),
    ),
    _FeatureShortcutData(
      icon: Icons.notifications_active,
      title: 'Notification Lab',
      description: 'Eksperimen lifecycle notifikasi modul 6.',
      destinationBuilder: (_) => const NotificationCenterScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final products = dummyProducts;
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
                          icon: Icons.favorite_border,
                          onPressed: () => Get.to(() => const WishlistScreen()),
                        ),
                        AppSpacing.hItem,
                        RoundedIconButton(
                          icon: Icons.notifications_active_outlined,
                          onPressed: () =>
                              Get.toNamed(AppRoutes.notificationCenter),
                        ),
                        AppSpacing.hItem,
                        RoundedIconButton(
                          icon: Icons.shopping_bag_outlined,
                          onPressed: () => onNavigateToTab(3),
                        ),
                      ],
                    ),
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
                      onPressed: () => onNavigateToTab(1),
                      expanded: false,
                    ),
                    const SizedBox(height: 16),
                    _SearchField(onTap: () => onNavigateToTab(1)),
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
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                ),
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
              Padding(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Eksperimen Pembelajaran',
                      subtitle: 'Akses cepat fitur tugas modul',
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = experiments[index];
                        return _ExperimentTile(data: item);
                      },
                      separatorBuilder: (_, __) => AppSpacing.vItem,
                      itemCount: experiments.length,
                    ),
                    AppSpacing.vSection,
                  ],
                ),
              ),
              _Footer(themeController: themeController),
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

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Cari baju impianmu...',
              prefixIcon: Icon(Icons.search),
            ),
            onTap: onTap,
          ),
        ),
        AppSpacing.hItem,
        RoundedIconButton(
          icon: Icons.tune,
          onPressed: () =>
              Get.snackbar('Filter', 'Fitur filter akan segera hadir'),
        ),
      ],
    );
  }
}

class _ExperimentTile extends StatelessWidget {
  const _ExperimentTile({required this.data});

  final _FeatureShortcutData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Get.to(() => data.destinationBuilder(context)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: theme.brightness == Brightness.dark
                ? null
                : AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.lavender,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(data.icon, color: AppColors.primaryPink),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.description,
                      style: const TextStyle(color: AppColors.softGray),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.softGray,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureShortcutData {
  const _FeatureShortcutData({
    required this.icon,
    required this.title,
    required this.description,
    required this.destinationBuilder,
  });

  final IconData icon;
  final String title;
  final String description;
  final WidgetBuilder destinationBuilder;
}

class _PromoBannerSection extends StatelessWidget {
  const _PromoBannerSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSpacing.vSection,
        Padding(
          padding: AppSpacing.pagePadding,
          child: _SectionHeader(
            title: 'Promo Interaktif',
            subtitle: 'Sentuh banner untuk animasi halus',
          ),
        ),
        const SizedBox(height: 12),
        const AnimatedBannerImplicit(),
        AppSpacing.vItem,
        const AnimatedBannerExplicit(),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.themeController});

  final ThemeController themeController;

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
          Obx(
            () => Row(
              children: [
                IconButton(
                  onPressed: () =>
                      themeController.setThemeMode(ThemeMode.light),
                  icon: Icon(
                    Icons.light_mode,
                    color: themeController.themeMode.value == ThemeMode.light
                        ? AppColors.primaryPink
                        : Colors.white54,
                  ),
                ),
                IconButton(
                  onPressed: () => themeController.setThemeMode(ThemeMode.dark),
                  icon: Icon(
                    Icons.dark_mode,
                    color: themeController.themeMode.value == ThemeMode.dark
                        ? AppColors.primaryPink
                        : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vItem,
          const Text(
            '© 2025 Wida Collection. All rights reserved.',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
