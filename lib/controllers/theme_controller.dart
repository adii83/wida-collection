import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/preferences_service.dart';

class ThemeController extends GetxController {
  ThemeController(this._preferencesService);

  final PreferencesService _preferencesService;

  final themeMode = ThemeMode.light.obs;
  final seedColor = const Color(0xFFE91E63).obs;

  final List<Color> availableSeeds = const [
    Color(0xFFE91E63), // pink
    Color(0xFF7C4DFF), // deep purple
    Color(0xFF26A69A), // teal
    Color(0xFFFFB300), // amber
    Color(0xFF42A5F5), // blue
  ];

  @override
  void onInit() {
    super.onInit();
    if (_preferencesService.isReady) {
      final sw = Stopwatch()..start();
      themeMode.value = _preferencesService.loadThemeMode();
      seedColor.value = _preferencesService.loadSeedColor(seedColor.value);
      sw.stop();
      debugPrint('Prefs read: ${sw.elapsedMilliseconds} ms');
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
    final sw = Stopwatch()..start();
    _preferencesService.saveThemeMode(mode).whenComplete(() {
      sw.stop();
      debugPrint('Prefs write (theme): ${sw.elapsedMilliseconds} ms');
    });
  }

  void setSeedColor(Color color) {
    seedColor.value = color;
    final sw = Stopwatch()..start();
    _preferencesService.saveSeedColor(color).whenComplete(() {
      sw.stop();
      debugPrint('Prefs write (color): ${sw.elapsedMilliseconds} ms');
    });
  }

  bool isSelected(Color color) => seedColor.value == color;
}
