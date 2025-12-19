import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_controller.dart';
import 'admin_product_management_screen.dart';
import 'admin_order_management_screen.dart';
import 'admin_refund_management_screen.dart';
import 'admin_notification_screen.dart';
import 'auth_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _statistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoadingStats = true);
    final adminController = Get.find<AdminController>();
    final stats = await adminController.getStatistics();
    setState(() {
      _statistics = stats;
      _isLoadingStats = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminController = Get.find<AdminController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () {
                    // Tutup popup menu terlebih dahulu
                    Navigator.pop(context);
                    adminController.logout();
                    // Arahkan kembali ke halaman login unified
                    Get.offAll(() => const AuthScreen());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStatistics,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Obx(() {
                final admin = adminController.currentAdmin.value;
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.admin_panel_settings,
                                size: 35,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang!',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    admin?.name ?? 'Admin',
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    admin?.role.toUpperCase() ?? 'ADMIN',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Statistics Cards
              Text(
                'Statistik',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _isLoadingStats
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          icon: Icons.shopping_cart,
                          title: 'Total Order',
                          value: '${_statistics?['total_orders'] ?? 0}',
                          color: Colors.blue,
                        ),
                        _buildStatCard(
                          icon: Icons.pending_actions,
                          title: 'Pending Order',
                          value: '${_statistics?['pending_orders'] ?? 0}',
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          icon: Icons.attach_money,
                          title: 'Total Revenue',
                          value:
                              'Rp ${(_statistics?['total_revenue'] ?? 0).toStringAsFixed(0)}',
                          color: Colors.green,
                        ),
                        _buildStatCard(
                          icon: Icons.money_off,
                          title: 'Pending Refund',
                          value: '${_statistics?['pending_refunds'] ?? 0}',
                          color: Colors.red,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // Menu Cards
              Text(
                'Menu Admin',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                icon: Icons.inventory,
                title: 'Kelola Produk',
                subtitle: 'Tambah, edit, dan hapus produk',
                color: Colors.purple,
                onTap: () => Get.to(() => const AdminProductManagementScreen()),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                icon: Icons.list_alt,
                title: 'Kelola Order',
                subtitle: 'Update status dan tracking order',
                color: Colors.blue,
                onTap: () => Get.to(() => const AdminOrderManagementScreen()),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                icon: Icons.money_off,
                title: 'Kelola Refund',
                subtitle: 'Proses permintaan refund',
                color: Colors.red,
                onTap: () => Get.to(() => const AdminRefundManagementScreen()),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                icon: Icons.notifications,
                title: 'Kirim Notifikasi',
                subtitle: 'Kirim notifikasi ke pengguna',
                color: Colors.orange,
                onTap: () => Get.to(() => const AdminNotificationScreen()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
