import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'controller/auth_controller.dart';
import 'controller/cloud_note_controller.dart';
import 'controller/local_note_controller.dart';
import 'controller/theme_controller.dart';
import 'controller/wishlist_controller.dart';
import 'controller/lookbook_controller.dart';
import 'controller/order_controller.dart';
import 'controller/capsule_planner_controller.dart';
import 'screens/home_screen.dart';
import 'services/hive_service.dart';
import 'services/preferences_service.dart';
import 'services/supabase_service.dart';

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

  Get.put(ThemeController(preferences), permanent: true);
  Get.put(LocalNoteController(hiveService), permanent: true);
  final authController = Get.put(
    AuthController(supabaseService),
    permanent: true,
  );
  Get.put(
    WishlistController(hiveService, supabaseService, authController),
    permanent: true,
  );
  Get.put(LookbookController(hiveService), permanent: true);
  Get.put(OrderController(supabaseService, authController), permanent: true);
  Get.put(CapsulePlannerController(hiveService, preferences), permanent: true);
  Get.put(
    CloudNoteController(supabaseService, authController),
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
        title: 'Winda Collection',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(themeController.seedColor.value),
        darkTheme: AppTheme.dark(themeController.seedColor.value),
        themeMode: themeController.themeMode.value,
        home: const HomeScreen(),
      ),
    );
  }
}
