import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winda_collection/controllers/theme_controller.dart';
import 'package:winda_collection/services/preferences_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController', () {
    late PreferencesService preferencesService;
    late ThemeController controller;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferencesService = await PreferencesService().init();
      controller = ThemeController(preferencesService);
    });

    test(
      'memuat mode default Light dan warna awal dari shared_preferences',
      () {
        expect(controller.themeMode.value, ThemeMode.light);
        expect(controller.seedColor.value, const Color(0xFFE91E63));
      },
    );

    test('menyimpan perubahan mode dan warna', () async {
      controller.setThemeMode(ThemeMode.dark);
      controller.setSeedColor(const Color(0xFF42A5F5));

      // tunggu microtask yang berasal dari penyimpanan async
      await Future.delayed(Duration.zero);

      expect(controller.themeMode.value, ThemeMode.dark);
      expect(preferencesService.loadThemeMode(), ThemeMode.dark);
      expect(controller.seedColor.value, const Color(0xFF42A5F5));
      expect(
        preferencesService.loadSeedColor(const Color(0xFFE91E63)),
        const Color(0xFF42A5F5),
      );
    });
  });
}
