import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: seedColor,
      fontFamily: 'sans',
    );
  }

  static ThemeData dark(Color seedColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: seedColor,
      fontFamily: 'sans',
    );
  }
}
