import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controllers/auth_controller.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import 'auth_screen.dart';
import 'wishlist_screen.dart';
import 'admin_login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return SafeArea(
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
                AppSpacing.section,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8FB1), Color(0xFFFF5E9D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Text(
                      _initial(auth.currentUser.value?.email ?? 'User'),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    auth.currentUser.value?.email ?? 'user@widacollection.com',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Member sejak 2024',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      _ProfileStat(label: 'Pesanan', value: '12'),
                      _ProfileStat(label: 'Dikirim', value: '1'),
                      _ProfileStat(label: 'Wishlist', value: '8'),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.vSection,
            Padding(
              padding: AppSpacing.pagePadding,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.edit,
                    title: 'Edit Profil',
                    subtitle: 'Perbarui data diri dan alamat',
                    onTap: () => Get.snackbar(
                      'Segera hadir',
                      'Fitur edit profil masih dalam pengembangan',
                    ),
                  ),
                  AppSpacing.vItem,
                  _MenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Pesanan Saya',
                    subtitle: 'Cek riwayat pembelian',
                    onTap: () => Get.snackbar('Info', 'Belum ada pesanan baru'),
                  ),
                  AppSpacing.vItem,
                  _MenuTile(
                    icon: Icons.favorite_border,
                    title: 'Wishlist',
                    subtitle: 'Lihat item favoritmu',
                    onTap: () => Get.to(() => const WishlistScreen()),
                  ),
                  const SizedBox(height: 12),
                  _MenuTile(
                    icon: Icons.settings,
                    title: 'Pengaturan',
                    subtitle: 'Mode gelap, bahasa, keamanan',
                    onTap: () => Get.snackbar(
                      'Info',
                      'Pengaturan lanjutan tersedia di halaman tema',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MenuTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    subtitle: 'Kelola produk, order & notifikasi',
                    iconColor: Colors.purple,
                    onTap: () => Get.to(() => const AdminLoginScreen()),
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
                  const Text(
                    'Riwayat Pesanan',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  AppSpacing.vItem,
                  _OrderTile(
                    statusLabel: 'Dikirim',
                    statusColor: AppColors.primaryPink,
                    orderId: '#THF12345678',
                    date: '20 Nov 2025',
                    total: 'Rp 334.000',
                    items: '2 items',
                  ),
                  const SizedBox(height: 12),
                  _OrderTile(
                    statusLabel: 'Selesai',
                    statusColor: AppColors.success,
                    orderId: '#THF12345679',
                    date: '15 Nov 2025',
                    total: 'Rp 149.000',
                    items: '1 item',
                  ),
                ],
              ),
            ),
            AppSpacing.vSection,
            Padding(
              padding: AppSpacing.pagePadding,
              child: GradientButton(
                label: auth.isLoggedIn ? 'Logout' : 'Login',
                onPressed: () async {
                  if (auth.isLoggedIn) {
                    await auth.signOut();
                    Get.snackbar('Logout', 'Kamu sudah keluar dari akun.');
                  } else {
                    Get.to(() => const AuthScreen());
                  }
                },
              ),
            ),
            AppSpacing.vSection,
          ],
        ),
      ),
    );
  }

  String _initial(String text) => text.isEmpty ? 'W' : text[0].toUpperCase();
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : AppShadows.card,
        ),
        child: Row(
          children: [
            RoundedIconButton(
              icon: icon,
              onPressed: onTap,
              iconColor: iconColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.softGray),
                  ),
                ],
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

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.statusLabel,
    required this.statusColor,
    required this.orderId,
    required this.date,
    required this.total,
    required this.items,
  });

  final String statusLabel;
  final Color statusColor;
  final String orderId;
  final String date;
  final String total;
  final String items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$date • $items',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.softGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            total,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
