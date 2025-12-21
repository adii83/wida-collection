import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_orders_controller.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import '../widgets/order_detail_sheet.dart';
import '../widgets/order_card.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.isRegistered<UserOrdersController>(tag: 'user-orders')
        ? Get.find<UserOrdersController>(tag: 'user-orders')
        : Get.put(
            UserOrdersController(Get.find<SupabaseService>()),
            tag: 'user-orders',
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final err = controller.error.value;
        if (err != null && controller.orders.isEmpty) {
          return _EmptyState(message: err, onRetry: controller.fetchMyOrders);
        }

        if (controller.orders.isEmpty) {
          return _EmptyState(
            message: 'Belum ada pesanan.',
            onRetry: controller.fetchMyOrders,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchMyOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = controller.orders[index];
              return OrderCard(
                order: order,
                heroTagPrefix: 'history',
                onTap: () => _showOrderDetail(context, order),
              );
            },
          ),
        );
      }),
    );
  }

  void _showOrderDetail(BuildContext context, OrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return OrderDetailSheet(order: order);
            },
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }
}
