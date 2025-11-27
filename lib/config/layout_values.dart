import 'package:flutter/widgets.dart';

/// Centralized spacing tokens to keep paddings consistent across screens.
class AppSpacing {
  static const double page = 24;
  static const double section = 24;
  static const double item = 12;
  static const double heroTop = 32;

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: page);

  static const EdgeInsets pagePaddingWithTop = EdgeInsets.fromLTRB(
    page,
    heroTop,
    page,
    0,
  );

  static const SizedBox vHero = SizedBox(height: heroTop);
  static const SizedBox vSection = SizedBox(height: section);
  static const SizedBox vItem = SizedBox(height: item);
  static const SizedBox hItem = SizedBox(width: item);
}
