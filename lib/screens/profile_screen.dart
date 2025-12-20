import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../config/design_tokens.dart';
import '../config/layout_values.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_orders_controller.dart';
import '../controllers/wishlist_controller.dart';
import '../services/supabase_service.dart';
import '../widgets/gradient_button.dart';
import '../widgets/rounded_icon_button.dart';
import '../widgets/success_dialog.dart';
import 'auth_screen.dart';
import 'wishlist_screen.dart';
import 'user_orders_screen.dart';
import 'edit_profile_screen.dart';
import 'auth_gate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = Get.find<AuthController>();
  late final UserOrdersController _ordersController;
  late final WishlistController _wishlistController;
  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    _wishlistController = Get.find<WishlistController>();
    _ordersController =
        Get.isRegistered<UserOrdersController>(tag: 'user-orders')
        ? Get.find<UserOrdersController>(tag: 'user-orders')
        : Get.put(
            UserOrdersController(Get.find<SupabaseService>()),
            tag: 'user-orders',
          );

    // Keep profile order summary synced with auth changes.
    _ordersController.fetchMyOrders();
    _authWorker = ever(
      auth.currentUser,
      (_) => _ordersController.fetchMyOrders(),
    );
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      final file = File(image.path);
      final success = await auth.updateProfilePicture(file);
      if (success) {
        SuccessDialog.show(
          title: 'Berhasil!',
          subtitle: 'Foto profil baru keren banget!',
        );
      }
    }
  }

  void _showProfileImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Close background tap
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(color: Colors.black87),
              ),
            ),
            // Image
            InteractiveViewer(
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                  maxHeight: 400,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  // Game-like Avatar
                  Obx(
                    () => GestureDetector(
                      onTap: () {
                        if (auth.profile.value?.avatarUrl != null) {
                          _showProfileImage(auth.profile.value!.avatarUrl!);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                24,
                              ), // Squircle
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 4, // Outer glass ring
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4), // White spacing
                              decoration: BoxDecoration(
                                color: AppColors.primaryPink,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryPink,
                                  width: 2,
                                ),
                                image: auth.profile.value?.avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(
                                          auth.profile.value!.avatarUrl!,
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: auth.profile.value?.avatarUrl == null
                                  ? Center(
                                      child: Text(
                                        _initial(
                                          auth.profile.value?.username ??
                                              auth.profile.value?.fullName ??
                                              auth.currentUser.value?.email ??
                                              'User',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          // Edit Icon Button
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: AppColors.primaryPink,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final profile = auth.profile.value;
                    final username = profile?.username;
                    final fullName = profile?.fullName;
                    final email =
                        auth.currentUser.value?.email ??
                        'user@widacollection.com';
                    // Primary: nama lengkap (atau email jika belum ada)
                    final hasFullName =
                        fullName != null && fullName.trim().isNotEmpty;
                    final primaryText = hasFullName ? fullName.trim() : email;

                    // Secondary: username (jika ada)
                    final hasUsername =
                        username != null && username.trim().isNotEmpty;

                    // Loading indicator
                    if (auth.isLoading.value &&
                        auth.lastError.value?.contains('maksimal') != true) {
                      return const Text(
                        'Mengunggah...',
                        style: TextStyle(color: Colors.white70),
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          primaryText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        if (hasUsername)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '@${username.trim()}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 24),
                  Obx(() {
                    final orders = _ordersController.orders;
                    final totalOrders = orders.length;
                    final shippedCount = orders
                        .where((o) => o.status.toLowerCase() == 'shipped')
                        .length;
                    final wishlistCount = _wishlistController.wishlist.length;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ProfileStat(label: 'Pesanan', value: '$totalOrders'),
                        _ProfileStat(label: 'Dikirim', value: '$shippedCount'),
                        _ProfileStat(
                          label: 'Wishlist',
                          value: '$wishlistCount',
                        ),
                      ],
                    );
                  }),
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
                    onTap: () => Get.to(() => const EditProfileScreen()),
                  ),
                  AppSpacing.vItem,
                  _MenuTile(
                    icon: Icons.inventory_2_outlined,
                    title: 'Pesanan Saya',
                    subtitle: 'Cek riwayat pembelian',
                    onTap: () => Get.to(() => const UserOrdersScreen()),
                  ),
                  AppSpacing.vItem,
                  _MenuTile(
                    icon: Icons.favorite_border,
                    title: 'Wishlist',
                    subtitle: 'Lihat item favoritmu',
                    onTap: () => Get.to(() => const WishlistScreen()),
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
                  Obx(() {
                    if (_ordersController.isLoading.value &&
                        _ordersController.orders.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final orders = _ordersController.orders;
                    if (orders.isEmpty) {
                      return Text(
                        auth.isLoggedIn
                            ? 'Belum ada pesanan.'
                            : 'Login untuk melihat riwayat pesanan.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.softGray,
                        ),
                      );
                    }

                    final recent = orders.take(2).toList();
                    return Column(
                      children: [
                        for (int i = 0; i < recent.length; i++) ...[
                          GestureDetector(
                            onTap: () => Get.to(() => const UserOrdersScreen()),
                            child: _OrderTile(
                              statusLabel: _statusLabel(recent[i].status),
                              statusColor: _statusColor(recent[i].status),
                              orderId: '#${_shortOrderId(recent[i].id)}',
                              date: _formatDate(recent[i].createdAt),
                              total:
                                  'Rp ${recent[i].totalAmount.toStringAsFixed(0)}',
                              items: '${_totalItems(recent[i])} items',
                            ),
                          ),
                          if (i != recent.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }),
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
                    Get.offAll(
                      () => const AuthGate(),
                    ); // Force navigation reset
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

  String _shortOrderId(String id) {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(0, 8).toUpperCase();
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  int _totalItems(dynamic order) {
    try {
      // order is OrderModel, but keep it tolerant to avoid extra imports here.
      final items = order.items as List;
      int sum = 0;
      for (final it in items) {
        sum += (it.quantity as int);
      }
      return sum;
    } catch (_) {
      return 0;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Diterima';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return AppColors.primaryPink;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
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
                  color: statusColor.withOpacity(0.15),
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
