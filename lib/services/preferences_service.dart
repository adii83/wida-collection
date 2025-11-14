import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService extends GetxService {
  static const _themeModeKey = 'theme_mode';
  static const _seedColorKey = 'theme_seed_color';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<PreferencesService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    return this;
  }

  bool get isReady => _initialized;

  ThemeMode loadThemeMode() {
    final storedValue = _prefs.getString(_themeModeKey);
    switch (storedValue) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
      _ => 'light',
    };
    await _prefs.setString(_themeModeKey, value);
  }

  Color loadSeedColor(Color fallback) {
    final colorValue = _prefs.getInt(_seedColorKey);
    if (colorValue == null) return fallback;
    return Color(colorValue);
  }

  Future<void> saveSeedColor(Color color) async {
    int channel(double component) => ((component * 255.0).round()) & 0xff;
    final argb =
        (channel(color.a) << 24) |
        (channel(color.r) << 16) |
        (channel(color.g) << 8) |
        channel(color.b);
    await _prefs.setInt(_seedColorKey, argb);
  }
}
