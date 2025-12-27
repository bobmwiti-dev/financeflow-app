import 'package:flutter/material.dart';

/// Extensions for the Color class to enhance functionality
extension ColorExtensions on Color {
  /// Creates a new color with the specified alpha, or the current alpha if not provided
  Color withValues({num? alpha, int? red, int? green, int? blue}) {
    int resolvedAlpha;
    if (alpha == null) {
      resolvedAlpha = a.toInt();
    } else {
      if (alpha is double) {
        // If alpha provided as 0.0-1.0 fraction convert to 0-255
        resolvedAlpha = (alpha.clamp(0.0, 1.0) * 255).round();
      } else {
        // Assume int in 0-255 range
        resolvedAlpha = (alpha as int).clamp(0, 255);
      }
    }
    return Color.fromARGB(
      resolvedAlpha,
      red ?? r.toInt(),
      green ?? g.toInt(),
      blue ?? b.toInt(),
    );
  }

  /// Create a lighter version of this color
  Color lighter([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    
    return hslLight.toColor();
  }

  /// Create a darker version of this color
  Color darker([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    
    return hslDark.toColor();
  }
  
  /// Returns whether the color is light or dark
  bool get isLight => computeLuminance() > 0.5;
}
