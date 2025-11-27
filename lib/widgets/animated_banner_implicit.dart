import 'package:flutter/material.dart';

import '../config/layout_values.dart';

class AnimatedBannerImplicit extends StatefulWidget {
  const AnimatedBannerImplicit({
    super.key,
    this.margin = AppSpacing.pagePadding,
  });

  final EdgeInsetsGeometry margin;

  @override
  State<AnimatedBannerImplicit> createState() => _AnimatedBannerImplicitState();
}

class _AnimatedBannerImplicitState extends State<AnimatedBannerImplicit> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: _expanded ? 180 : 120,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: Colors.pink.shade100,
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: AssetImage('assets/images/thrift1.jpg'),
            fit: BoxFit.cover,
            opacity: 0.6,
          ),
        ),
        alignment: Alignment.center,
        child: const Text(
          '🔥 Promo 50% Semua Produk 🔥',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
