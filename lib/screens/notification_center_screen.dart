import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notification_controller.dart';
import '../models/app_notification.dart';
import '../routes/app_routes.dart';

class NotificationCenterScreen extends GetView<NotificationController> {
  const NotificationCenterScreen({super.key});

  static const routeName = AppRoutes.notificationCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Notifikasi'),
        actions: [
          Obx(
            () => IconButton(
              onPressed: controller.notifications.isEmpty
                  ? null
                  : controller.clearAllNotifications,
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Bersihkan semua',
            ),
          ),
        ],
      ),
      body: Obx(() {
        final visibleNotifications = controller.notifications
            .where((entry) => entry.data['origin'] != 'local')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (visibleNotifications.isEmpty)
              _EmptyState(permissionGranted: controller.permissionGranted.value)
            else
              ...visibleNotifications.map(
                (entry) => _NotificationTile(
                  entry: entry,
                  onTap: () => controller.openEntry(entry),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.entry, this.onTap});

  final AppNotification entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final localDate = entry.receivedAt.toLocal();
    final dateLabel =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';
    final badgeColor = entry.type == NotificationType.promo
        ? Colors.pinkAccent
        : entry.type == NotificationType.orderStatus
        ? Colors.teal
        : Colors.grey;
    const dateColor = Color.fromARGB(255, 169, 169, 169);
    final iconData = entry.type == NotificationType.promo
        ? Icons.local_offer
        : entry.type == NotificationType.orderStatus
        ? Icons.inventory_2
        : Icons.notifications;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.15),
          child: Icon(iconData, color: badgeColor),
        ),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text.rich(
          TextSpan(
            text: '${entry.body}\n',
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: dateLabel,
                style: TextStyle(color: dateColor),
              ),
            ],
          ),
        ),
        trailing: onTap == null ? null : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.permissionGranted});

  final bool permissionGranted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.notifications_off, size: 48),
            const SizedBox(height: 12),
            Text(
              permissionGranted
                  ? 'Belum ada notifikasi terbaru.'
                  : 'Izin notifikasi belum aktif. Aktifkan notifikasi di pengaturan perangkat.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
