import 'package:flutter/material.dart';

class RoundedIconButton extends StatelessWidget {
  const RoundedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 44,
    this.iconSize = 20,
    this.tooltip,
    this.showShadow = true,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;
  final String? tooltip;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final resolvedBackground = backgroundColor ?? scheme.surface;
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.08);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: resolvedBackground,
            shape: BoxShape.circle,
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: iconSize, color: iconColor ?? scheme.primary),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
