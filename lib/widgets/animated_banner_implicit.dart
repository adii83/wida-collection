import 'package:flutter/material.dart';

class AnimatedBannerImplicit extends StatefulWidget {
  const AnimatedBannerImplicit({super.key, this.onHeightChanged});

  static const double collapsedHeight = 150;
  static const double expandedHeight = 210;

  final ValueChanged<double>? onHeightChanged;

  @override
  State<AnimatedBannerImplicit> createState() => _AnimatedBannerImplicitState();
}

class _AnimatedBannerImplicitState extends State<AnimatedBannerImplicit> {
  bool _expanded = false;
  double? _lastReportedHeight;

  double get _currentHeight => _expanded
      ? AnimatedBannerImplicit.expandedHeight
      : AnimatedBannerImplicit.collapsedHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyHeight());
  }

  void _notifyHeight() {
    final currentHeight = _currentHeight;
    if (_lastReportedHeight == currentHeight) return;
    _lastReportedHeight = currentHeight;
    widget.onHeightChanged?.call(currentHeight);
  }

  void _handleTap() {
    setState(() => _expanded = !_expanded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyHeight());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Align(
        alignment: Alignment.topLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: _currentHeight,
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
      ),
    );
  }
}
