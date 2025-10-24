import 'package:flutter/material.dart';

class AnimatedBannerExplicit extends StatefulWidget {
  const AnimatedBannerExplicit({super.key});

  @override
  State<AnimatedBannerExplicit> createState() => _AnimatedBannerExplicitState();
}

class _AnimatedBannerExplicitState extends State<AnimatedBannerExplicit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heightAnimation = Tween<double>(
      begin: 100,
      end: 180,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _heightAnimation,
        builder: (context, child) => Container(
          width: double.infinity,
          height: _heightAnimation.value,
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
    );
  }
}
