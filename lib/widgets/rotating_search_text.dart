import 'dart:async';
import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

class RotatingSearchText extends StatefulWidget {
  const RotatingSearchText({super.key, this.textColor, this.fontSize = 14});

  final Color? textColor;
  final double fontSize;

  @override
  State<RotatingSearchText> createState() => _RotatingSearchTextState();
}

class _RotatingSearchTextState extends State<RotatingSearchText> {
  static const _prompts = [
    'Outfit Pria',
    'Vintage Outfit',
    'Old Money Style',
    'Outfit Wanita',
    'Outfit Anak',
  ];

  late int _currentPrompt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentPrompt = 0;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _currentPrompt = (_currentPrompt + 1) % _prompts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Text(
        _prompts[_currentPrompt],
        key: ValueKey(_currentPrompt),
        style: TextStyle(
          color: widget.textColor ?? AppColors.softGray,
          fontSize: widget.fontSize,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
