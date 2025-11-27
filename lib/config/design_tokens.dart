import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryPink = Color(0xFFFF4D8D);
  static const Color primaryPinkDark = Color(0xFFFD2F74);
  static const Color primaryPinkLight = Color(0xFFFFB5D0);
  static const Color blush = Color(0xFFFFEEF6);
  static const Color lavender = Color(0xFFF4ECFF);
  static const Color mint = Color(0xFFE8F7EF);
  static const Color softGray = Color(0xFF8F9BB3);
  static const Color charcoal = Color(0xFF1A1D2E);
  static const Color warning = Color(0xFFFFC542);
  static const Color success = Color(0xFF2BC48A);
}

class AppGradients {
  static const LinearGradient hero = LinearGradient(
    colors: [Color(0xFFFFF1F6), Color(0xFFFFD4E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pill = LinearGradient(
    colors: [AppColors.primaryPink, Color(0xFFFF799A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient floatingAction = LinearGradient(
    colors: [Color(0xFFFF7096), Color(0xFFFF4D8D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static final card = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
}
