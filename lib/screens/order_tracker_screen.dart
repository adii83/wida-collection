import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/order_controller.dart';
import '../controller/auth_controller.dart';

class OrderTrackerScreen extends GetView<OrderController> {
  const OrderTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pelacak Pesanan & Pengiriman')),
      body: Obx(() {
        if (!auth.isLoggedIn) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Masuk ke akun Supabase terlebih dahulu melalui menu Catatan Cloud. Pesanan yang tersimpan di tabel orders akan otomatis muncul di sini dan diperbarui real-time begitu status berubah.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.orders.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada pesanan terdaftar. Tambahkan data dummy pada tabel orders di Supabase untuk melakukan simulasi tracking.',
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.orders.length,
          itemBuilder: (context, index) {
            final order = controller.orders[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(order.invoice),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${order.status}'),
                    Text('Pembayaran: ${order.paymentStatus}'),
                    Text('Resi: ${order.trackingNumber}'),
                    if (order.eta != null)
                      Text('Estimasi sampai: ${order.eta}'),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
