import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cloud_note_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/wishlist_controller.dart';
import 'controllers/cart_controller.dart';
import 'screens/auth_gate.dart';
import 'services/hive_service.dart';
import 'services/preferences_service.dart';
import 'services/supabase_service.dart';
import 'controllers/notification_controller.dart';
import 'services/notification_service.dart';
import 'services/product_service.dart';
import 'screens/notification_center_screen.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Dotenv load skipped: $e');
  }
  await Hive.initFlutter();

  final preferences = await Get.putAsync<PreferencesService>(
    () async => PreferencesService().init(),
    permanent: true,
  );

  final hiveService = await Get.putAsync<HiveService>(
    () async => HiveService().init(),
    permanent: true,
  );

  final supabaseService = await Get.putAsync<SupabaseService>(
    () async => SupabaseService().init(),
    permanent: true,
  );
  final notificationService = await Get.putAsync<NotificationService>(
    () async => NotificationService().init(),
    permanent: true,
  );
  final productService = await Get.putAsync<ProductService>(
    () async => ProductService().init(),
    permanent: true,
  );

  Get.put(ThemeController(preferences), permanent: true);
  final authController = Get.put(
    AuthController(supabaseService),
    permanent: true,
  );
  Get.put(
    WishlistController(hiveService, supabaseService, authController),
    permanent: true,
  );
  Get.put(
    CartController(hiveService, supabaseService, authController),
    permanent: true,
  );
  Get.put(
    CloudNoteController(supabaseService, authController, hiveService),
    permanent: true,
  );
  Get.put(
    NotificationController(notificationService, productService),
    permanent: true,
  );

  runApp(const WindaCollectionApp());
}

class WindaCollectionApp extends StatelessWidget {
  const WindaCollectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Obx(
      () => GetMaterialApp(
        title: 'Wida Collection',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(themeController.seedColor.value),
        darkTheme: AppTheme.dark(themeController.seedColor.value),
        themeMode: themeController.themeMode.value,
        getPages: [
          GetPage(
            name: AppRoutes.notificationCenter,
            page: NotificationCenterScreen.new,
          ),
        ],
        home: const AuthGate(),
      ),
    );
  }
}
