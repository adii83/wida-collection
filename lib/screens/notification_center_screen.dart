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
          IconButton(
            onPressed: controller.markAllAsRead,
            icon: const Icon(Icons.mark_email_read),
            tooltip: 'Tandai semua sudah dibaca',
          ),
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
        '${localDate.day}/${localDate.month}/${localDate.year} ${localDate.hour}:${localDate.minute.toString().padLeft(2, '0')}';

    // Visual distinction for unread notifications
    final backgroundColor = entry.isRead
        ? Colors.white
        : const Color(0xFFFFF0F5); // Light Pink for unread

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: backgroundColor,
      elevation: entry.isRead ? 0.5 : 2, // Slight elevation pop for unread
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: entry.isRead
            ? BorderSide.none
            : const BorderSide(color: Colors.pinkAccent, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 24,
          child: Image.asset(
            'assets/images/logo.png', // The requested "iclauncher" / logo
            fit: BoxFit.contain,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: entry.isRead ? FontWeight.w500 : FontWeight.bold,
                ),
              ),
            ),
            if (!entry.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.pinkAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              entry.body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: entry.isRead ? Colors.grey[700] : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dateLabel,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
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
