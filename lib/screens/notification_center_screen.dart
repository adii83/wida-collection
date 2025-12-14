import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            onPressed: controller.refreshFcmToken,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh token',
          ),
        ],
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTokenCard(context),
            const SizedBox(height: 12),
            _PayloadSampleCard(),
            const SizedBox(height: 16),
            if (controller.notifications.isEmpty)
              _EmptyState(permissionGranted: controller.permissionGranted.value)
            else
              ...controller.notifications
                  .map(
                    (entry) => _NotificationTile(
                      entry: entry,
                      onTap: () => controller.openEntry(entry),
                    ),
                  )
                  ,
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard(BuildContext context) {
    final token = controller.fcmToken.value ?? 'Belum tersedia';
    final granted = controller.permissionGranted.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active),
                const SizedBox(width: 8),
                Text(
                  granted
                      ? 'Izin notifikasi aktif'
                      : 'Izin notifikasi belum diberikan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('FCM Token', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            SelectableText(token, style: const TextStyle(fontSize: 13)),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: controller.fcmToken.value == null
                    ? null
                    : () {
                        Clipboard.setData(ClipboardData(text: token));
                        Get.snackbar(
                          'Token disalin',
                          'Gunakan token ini di Firebase Console',
                        );
                      },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Salin token'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.entry, required this.onTap});

  final AppNotification entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = '${entry.body}\nDiterima: ${entry.receivedAt.toLocal()}';
    final badgeColor = entry.type == NotificationType.promo
        ? Colors.pinkAccent
        : entry.type == NotificationType.orderStatus
        ? Colors.teal
        : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: badgeColor.withOpacity(0.15),
          child: Icon(
            entry.type == NotificationType.promo
                ? Icons.local_offer
                : entry.type == NotificationType.orderStatus
                ? Icons.inventory_2
                : Icons.notifications,
            color: badgeColor,
          ),
        ),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
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
                  ? 'Belum ada notifikasi terbaru. Kirim pesan dari Firebase Console untuk mulai eksperimen.'
                  : 'Izin notifikasi belum aktif. Izinkan notifikasi pada dialog Android 13+ lalu ulangi.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayloadSampleCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const sample =
        '{\n  "title": "Promo Payday 50%",\n  "body": "Voucher khusus loyal customer",\n  "type": "promo",\n  "productId": "p1"\n}';
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Format Payload FCM',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Kirim sebagai Data Message via Firebase Console:',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 8),
            SelectableText(sample, style: TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
