import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BrandLogo extends StatelessWidget {
  final String brand;
  final double size;
  final Color? fallbackColor;
  final IconData? fallbackIcon;

  const BrandLogo({
    super.key,
    required this.brand,
    this.size = 24.0,
    this.fallbackColor,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final logoPath = 'assets/logos/$brand.svg';
    
    return SvgPicture.asset(
      logoPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

class BrandLogoCircle extends StatelessWidget {
  final String brand;
  final double size;
  final Color? backgroundColor;
  final Color? fallbackColor;
  final IconData? fallbackIcon;

  const BrandLogoCircle({
    super.key,
    required this.brand,
    this.size = 40.0,
    this.backgroundColor,
    this.fallbackColor,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? Colors.grey.shade100,
      child: BrandLogo(
        brand: brand,
        size: size * 0.6, // Logo is 60% of circle size
        fallbackColor: fallbackColor,
        fallbackIcon: fallbackIcon,
      ),
    );
  }
}
