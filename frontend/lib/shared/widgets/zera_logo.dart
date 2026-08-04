import 'package:flutter/material.dart';

/// The official Zera Creative logo lockup. Never recolor, stretch, or
/// otherwise modify the source asset — only its display height is adjustable.
class ZeraLogo extends StatelessWidget {
  const ZeraLogo({super.key, this.height = 32});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/zera-logo-dark.png',
      height: height,
      fit: BoxFit.contain,
    );
  }
}
