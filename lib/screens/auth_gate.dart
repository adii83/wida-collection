import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/auth_controller.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class AuthGate extends GetWidget<AuthController> {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.canUseSupabase) {
        return const HomeScreen();
      }
      if (controller.isLoggedIn) {
        return const HomeScreen();
      }
      return const AuthScreen();
    });
  }
}
