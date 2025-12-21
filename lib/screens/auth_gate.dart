import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthGate extends GetWidget<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Check for deferred notification launch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<NotificationController>().consumeDeferredNotification();
    });

    // Jika Supabase tidak tersedia, langsung ke HomeScreen tanpa auth
    if (!controller.canUseSupabase) {
      return const HomeScreen();
    }

    // Reactive: pantau perubahan currentUser
    return Obx(() {
      final user = controller.currentUser.value;

      if (user != null) {
        if (controller.isAdmin) {
          return const AdminDashboardScreen();
        }
        return const HomeScreen();
      }

      return const AuthScreen();
    });
  }
}
