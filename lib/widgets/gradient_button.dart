import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final button = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppGradients.pill,
        borderRadius: BorderRadius.circular(40),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final content = Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: button,
    );

    return expanded
        ? SizedBox(width: double.infinity, child: _buildInkWell(content))
        : _buildInkWell(content);
  }

  Widget _buildInkWell(Widget child) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onPressed,
        child: child,
      ),
    );
  }
}
