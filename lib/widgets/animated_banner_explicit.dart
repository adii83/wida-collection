import 'package:flutter/material.dart';

class AnimatedBannerExplicit extends StatefulWidget {
  const AnimatedBannerExplicit({super.key, this.onHeightChanged});

  static const double collapsedHeight = 150;
  static const double expandedHeight = 210;

  final ValueChanged<double>? onHeightChanged;

  @override
  State<AnimatedBannerExplicit> createState() => _AnimatedBannerExplicitState();
}

class _AnimatedBannerExplicitState extends State<AnimatedBannerExplicit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heightAnimation =
        Tween<double>(
          begin: AnimatedBannerExplicit.collapsedHeight,
          end: AnimatedBannerExplicit.expandedHeight,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyHeight());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    _isExpanded = !_isExpanded;
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyHeight());
  }

  void _notifyHeight() {
    final targetHeight = _isExpanded
        ? AnimatedBannerExplicit.expandedHeight
        : AnimatedBannerExplicit.collapsedHeight;
    widget.onHeightChanged?.call(targetHeight);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) => Align(
          alignment: Alignment.topLeft,
          child: Container(
            width: double.infinity,
            height: _heightAnimation.value,
            decoration: BoxDecoration(
              color: Colors.pink.shade200,
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/images/thrift2.jpg'),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              '✨ Koleksi Terbaru Sudah Tiba ✨',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
